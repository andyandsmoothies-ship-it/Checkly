import os
import re
import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description="Verify schema and nullability contracts between backend DTOs and frontend Drift models.")
    parser.add_argument(
        "--advisory",
        action="store_true",
        help="Run in advisory mode (print warnings, do not fail build)."
    )
    return parser.parse_args()

def to_camel_case(s):
    """Converts PascalCase to camelCase."""
    if not s:
        return s
    return s[0].lower() + s[1:]

def parse_csharp_dtos(filepaths):
    """
    Parses C# files for record DTOs.
    Returns: dict of record_name -> dict of property_name -> (type, is_nullable)
    """
    dtos = {}
    
    # Regex to capture record signature and body
    # Support both single-line and multi-line record parameter lists
    record_pattern = re.compile(
        r'public\s+sealed\s+record\s+(\w+)\s*\((.*?)\);',
        re.DOTALL
    )
    
    for path in filepaths:
        if not os.path.exists(path):
            continue
            
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            
        for match in record_pattern.finditer(content):
            record_name = match.group(1)
            params_block = match.group(2)
            
            properties = {}
            # Parse parameters e.g., "Guid Id", "string? Description", "List<string>? CategoryTags"
            for param in params_block.split(','):
                param = param.strip()
                if not param:
                    continue
                parts = param.split()
                if len(parts) >= 2:
                    # The last part is the property name, second to last is the type
                    prop_name = parts[-1]
                    prop_type = parts[-2]
                    
                    is_nullable = prop_type.endswith('?')
                    clean_type = prop_type.rstrip('?')
                    
                    properties[prop_name] = (clean_type, is_nullable)
            
            dtos[record_name] = properties
            
    return dtos

def parse_drift_tables(filepath):
    """
    Parses lib/_shared/database/tables.dart for cache tables.
    Returns: dict of table_name -> dict of column_name -> (column_type, is_nullable)
    """
    tables = {}
    
    if not os.path.exists(filepath):
        return tables
        
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Regex to match Drift class Tables
    class_pattern = re.compile(
        r'class\s+(\w+)\s+extends\s+Table\s*\{(.*?)\}',
        re.DOTALL
    )
    
    # Regex to match Drift column getters e.g. "TextColumn get id => text()();" or "RealColumn get weight => real().nullable()();"
    column_pattern = re.compile(
        r'(\w+Column)\s+get\s+(\w+)\s*=>\s*([^;]+);'
    )
    
    for match in class_pattern.finditer(content):
        class_name = match.group(1)
        body = match.group(2)
        
        columns = {}
        for col_match in column_pattern.finditer(body):
            col_type = col_match.group(1)
            col_name = col_match.group(2)
            col_definition = col_match.group(3)
            
            is_nullable = '.nullable(' in col_definition
            columns[col_name] = (col_type, is_nullable)
            
        tables[class_name] = columns
        
    return tables

def main():
    args = get_args()
    workspace_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    
    csharp_files = [
        os.path.join(workspace_root, "server", "Features", "Templates", "Dtos.cs"),
        os.path.join(workspace_root, "server", "Features", "Templates", "SyncTemplates.cs")
    ]
    
    drift_file = os.path.join(workspace_root, "lib", "_shared", "database", "tables.dart")
    
    csharp_dtos = parse_csharp_dtos(csharp_files)
    drift_tables = parse_drift_tables(drift_file)
    
    # Mapping configuration: Backend DTO name -> Frontend Table name
    contract_mappings = {
        "TemplateDto": "CachedTemplates",
        "SyncGroupDto": "CachedGroups",
        "CriterionDto": "CachedCriteria"
    }

    type_compatibility = {
        "Guid": "TextColumn",
        "string": "TextColumn",
        "int": "IntColumn",
        "bool": "BoolColumn",
        "decimal": "RealColumn",
        "double": "RealColumn",
        "DateTimeOffset": "DateTimeColumn",
        "List<string>": "TextColumn" # Serialized as string in SQLite
    }

    drift_violations = []

    for dto_name, table_name in contract_mappings.items():
        if dto_name not in csharp_dtos:
            print(f"[WARN] DTO {dto_name} not found in backend code.")
            continue
        if table_name not in drift_tables:
            print(f"[WARN] Table {table_name} not found in Drift tables.")
            continue
            
        dto_fields = csharp_dtos[dto_name]
        table_cols = drift_tables[table_name]
        
        for field_name, (field_type, is_field_nullable) in dto_fields.items():
            col_name = to_camel_case(field_name)
            
            # 1. Existence check
            if col_name not in table_cols:
                drift_violations.append(
                    f"Missing column: Drift Table `{table_name}` is missing field `{col_name}` (expected from `{dto_name}.{field_name}`)"
                )
                continue
                
            col_type, is_col_nullable = table_cols[col_name]
            
            # 2. Type compatibility check
            expected_col_type = type_compatibility.get(field_type)
            if expected_col_type and expected_col_type != col_type:
                drift_violations.append(
                    f"Type mismatch on `{table_name}.{col_name}`: Drift uses `{col_type}` but backend `{dto_name}.{field_name}` is `{field_type}` (expects `{expected_col_type}`)"
                )
                
            # 3. Nullability alignment check
            # Exception: ID properties are always non-nullable primary keys in Drift, even if nullable in DTO endpoints.
            if col_name == "id" or col_name.endswith("Id"):
                continue
                
            if is_field_nullable != is_col_nullable:
                drift_violations.append(
                    f"Nullability mismatch on `{table_name}.{col_name}`: Drift is nullable={is_col_nullable} but backend `{dto_name}.{field_name}` is nullable={is_field_nullable}"
                )

    print("\n==========================================")
    print("      CHECKLY SYNC CONTRACT CHECKER        ")
    print("==========================================\n")

    if drift_violations:
        print("[FAIL] CONTRACT SCHEMA DRIFT VIOLATIONS FOUND:")
        for violation in drift_violations:
            print(f"  - {violation}")
        print()
        print("[TIP] Teacher Tip: Ensure that when you modify sync properties on the C# backend DTOs, you make matching schema and nullability changes in Drift's `tables.dart` file and run table migrations.")
        
        if args.advisory:
            print("\n[SUCCESS] Contract verification completed with warnings. (Exited successfully due to --advisory)")
            sys.exit(0)
        else:
            print("\n[FAIL] Sync contract verification failed. Please align database schemas.")
            sys.exit(1)
    else:
        print("[SUCCESS] All database schemas are in perfect alignment! Drift tables match backend sync DTOs.")
        sys.exit(0)

if __name__ == "__main__":
    main()
