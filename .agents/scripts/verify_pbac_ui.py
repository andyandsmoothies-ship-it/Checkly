import os
import re
import sys

def main():
    lib_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'lib', 'features')
    
    # Regex to find FloatingActionButton that isn't wrapped in PermissionGuard
    # Allow PermissionGuard, ChecklyFab (which has internal guards), or ternary checks (canWrite, etc.)
    fab_pattern = re.compile(r'floatingActionButton:\s*(?!(PermissionGuard|ChecklyFab|null|can[A-Z]\w*|_can[A-Z]\w*|has[A-Z]\w*|_has[A-Z]\w*))\w+')
    
    errors = []
    
    for root, _, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    if '// ignore_for_file: pbac_fab' in content:
                        continue
                        
                    matches = fab_pattern.finditer(content)
                    for match in matches:
                        # Find line number
                        line_num = content.count('\n', 0, match.start()) + 1
                        errors.append(f"{filepath}:{line_num} Unprotected FloatingActionButton found. (Add '// ignore_for_file: pbac_fab' to file if intended)")

    if errors:
        print("PBAC UI Verification Failed:")
        for err in errors:
            print(f"  {err}")
        sys.exit(1)
    else:
        print("PBAC UI Verification Passed: No unprotected FABs found.")
        sys.exit(0)

if __name__ == "__main__":
    main()
