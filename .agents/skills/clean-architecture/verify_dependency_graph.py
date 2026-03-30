"""
verify_dependency_graph.py — Architecture Dependency Gate
===========================================================
Usage:
    python .agents/scripts/verify_dependency_graph.py [solution_path]

Arguments:
    solution_path  Optional search directory. Defaults to CWD.

Exit Codes:
    0  — All architecture layers obey dependency inversion rules.
    1  — One or more layer violations detected.

Design Rules:
    - Never crashes: wraps XML parsing in try/catch.
    - Specifically enforces Clean Architecture / Onion layers:
          Domain       -> No external deps, no EF Core
          Application  -> Depends on Domain, no EF Core, no Infra, no API
          Infrastructure -> Depends on App/Domain
          API          -> Bootstrapper (depends on all, but usually via abstractions)
"""

import sys
import os
import xml.etree.ElementTree as ET
from pathlib import Path

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Define layer suffixes and the forbidden references for that layer
# Format: "ProjectSuffix": ( [Forbidden_Project_References], [Forbidden_Packages] )

ARCHITECTURE_RULES = {
    "Domain": (
        [".Application", ".Infrastructure", ".Api"],  # Project References
        ["Microsoft.EntityFrameworkCore", "Microsoft.AspNetCore"]  # Package References
    ),
    "Application": (
        [".Infrastructure", ".Api"],
        ["Microsoft.EntityFrameworkCore", "Microsoft.AspNetCore"]
    ),
    "Infrastructure": (
        [".Api"],
        [] # Infrastructure is allowed to reference EF Core and anything else
    ),
}

def remove_xml_namespaces(xml_string: str) -> str:
    """Removes xmlns declarations to simplify ElementTree parsing."""
    import re
    return re.sub(r'\sxmlns="[^"]+"', '', xml_string, count=1)


# ─────────────────────────────────────────────────────────────────────────────
# CORE ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

def analyze_csproj(csproj_path: Path) -> list[str]:
    violations: list[str] = []
    
    # Determine the layer based on project name suffix
    layer = None
    for known_layer in ARCHITECTURE_RULES.keys():
        if csproj_path.name.lower().endswith(f".{known_layer.lower()}.csproj"):
            layer = known_layer
            break
            
    if not layer:
        return [] # Not a structured layer, ignore
        
    forbidden_projects, forbidden_packages = ARCHITECTURE_RULES[layer]
    
    try:
        content = csproj_path.read_text(encoding="utf-8")
        content = remove_xml_namespaces(content)
        tree = ET.fromstring(content)
    except Exception as exc:
        return [f"XML Parse Error: {exc}"]
        
    # Check Project References
    for proj_ref in tree.findall(".//ProjectReference"):
        include_path = proj_ref.get("Include", "")
        for forbidden in forbidden_projects:
            # e.g., if checking Domain, we forbid "..\\MyApp.Application.csproj"
            if forbidden.lower() in include_path.lower():
                violations.append(
                    f"  LAYER VIOLATION ({layer}) : "
                    f"References forbidden project layer -> {os.path.basename(include_path)}"
                )
                
    # Check Package References
    for pkg_ref in tree.findall(".//PackageReference"):
        pkg_name = pkg_ref.get("Include", "")
        for forbidden in forbidden_packages:
            if pkg_name.lower().startswith(forbidden.lower()):
                violations.append(
                    f"  LAYER VIOLATION ({layer}) : "
                    f"References forbidden package -> {pkg_name}"
                )
                
    return violations


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    search_path = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()

    print(f"\n{'='*60}")
    print(f"  verify_dependency_graph.py — Architecture Gate")
    print(f"  Target : {search_path}")
    print(f"{'='*60}\n")

    if not os.path.exists(search_path):
        print(f"❌ FATAL: Path does not exist: {search_path}")
        sys.exit(1)

    project_files = list(Path(search_path).rglob("*.csproj"))

    if not project_files:
        print("  ⚠️  No .csproj files found.")
        sys.exit(0)

    print(f"  Scanning {len(project_files)} Project(s)...\n")

    all_violations: list[str] = []

    for csproj in project_files:
        violations = analyze_file(csproj)
        # Skip printing if it's not a recognized layer
        is_known_layer = any(csproj.name.lower().endswith(f".{l.lower()}.csproj") for l in ARCHITECTURE_RULES)
        
        if is_known_layer:
            if violations:
                print(f"  ❌ {csproj.name}:")
                for v in violations:
                    print(v)
                all_violations.extend(violations)
            else:
                print(f"  ✅ {csproj.name} — Architecture preserved")

    print(f"\n{'='*60}")

    if all_violations:
        print(f"\n❌ FAILED — {len(all_violations)} dependency inversion violation(s).\n")
        print("  Fix: The Domain layer must have zero dependencies (.Application, EF Core, HTTP).")
        print("       The Application layer must not reference .Infrastructure or .Api.\n")
        sys.exit(1)

    print(f"\n✅ ALL CHECKS PASSED — Clean Architecture layers preserved.\n")
    print(f"{'='*60}\n")
    sys.exit(0)


def analyze_file(csproj: Path) -> list[str]:
    return analyze_csproj(csproj)


if __name__ == "__main__":
    main()
