import os
import re
import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description="Scan project files for size and modularity limits.")
    parser.add_argument(
        "--advisory",
        action="store_true",
        help="Run in advisory mode (print warnings, do not fail build)."
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Specific files to scan. If empty, scans all files under features directories."
    )
    return parser.parse_args()

def scan_file_modularity(filepath):
    """
    Scans a C# or Dart file.
    Returns: (total_lines, function_violations)
    Where function_violations is a list of (function_name, line_count, start_line)
    """
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    function_violations = []

    # Regex to detect method declarations in C# and Dart
    method_pattern = re.compile(
        r'^\s*(?:public|private|protected|internal|static|async|override|\w+<[\w\s,<>]+>)?\s*[\w<>\[\]]+\s+(\w+)\s*\([^)]*\)\s*(?:async)?\s*\{?'
    )

    brace_count = 0
    in_method = False
    method_name = ""
    method_start_line = 0
    method_brace_level = 0

    for idx, line in enumerate(lines):
        line_stripped = line.strip()
        
        if not line_stripped or line_stripped.startswith("//") or line_stripped.startswith("/*") or line_stripped.startswith("*"):
            continue

        if not in_method:
            match = method_pattern.search(line)
            if match and "class" not in line and "namespace" not in line:
                method_name = match.group(1)
                if method_name not in ["if", "for", "while", "switch", "catch", "using", "lock"]:
                    in_method = True
                    method_start_line = idx + 1
                    method_brace_level = brace_count
                    
        for char in line:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == method_brace_level:
                    method_end_line = idx + 1
                    method_length = method_end_line - method_start_line + 1
                    if method_length > 30:
                        function_violations.append((method_name, method_length, method_start_line))
                    in_method = False

    return total_lines, function_violations

def main():
    args = get_args()
    workspace_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    
    file_violations = []
    function_violations_all = []

    if args.files:
        for filepath in args.files:
            abs_path = os.path.abspath(filepath)
            if not os.path.exists(abs_path):
                continue
            if not (abs_path.endswith(".dart") or abs_path.endswith(".cs")) or abs_path.endswith(".g.dart"):
                continue
            
            rel_path = os.path.relpath(abs_path, workspace_root)
            total_lines, func_errs = scan_file_modularity(abs_path)

            if total_lines > 350:
                file_violations.append((rel_path, total_lines))

            for func_name, f_lines, start_l in func_errs:
                function_violations_all.append((rel_path, func_name, f_lines, start_l))
    else:
        scan_dirs = [
            os.path.join(workspace_root, "lib", "features"),
            os.path.join(workspace_root, "server", "Features")
        ]

        for s_dir in scan_dirs:
            if not os.path.exists(s_dir):
                continue
                
            for root, _, files in os.walk(s_dir):
                if any(p in root.split(os.sep) for p in ["bin", "obj", "generated", ".dart_tool"]):
                    continue

                for file in files:
                    if (file.endswith(".dart") or file.endswith(".cs")) and not file.endswith(".g.dart"):
                        filepath = os.path.join(root, file)
                        rel_path = os.path.relpath(filepath, workspace_root)

                        total_lines, func_errs = scan_file_modularity(filepath)

                        if total_lines > 350:
                            file_violations.append((rel_path, total_lines))

                        for func_name, f_lines, start_l in func_errs:
                            function_violations_all.append((rel_path, func_name, f_lines, start_l))

    has_issues = False
    
    print("\n==========================================")
    print("      CHECKLY MODULARITY INDEX REPORT      ")
    print("==========================================\n")

    if file_violations:
        has_issues = True
        print("[FAIL] FILE SIZE VIOLATIONS (Limit: 400 lines, Warning > 350):")
        for filepath, lines in sorted(file_violations, key=lambda x: x[1], reverse=True):
            status = "CRITICAL (>400)" if lines > 400 else "WARNING (>350)"
            print(f"  [{status}] {filepath} has {lines} lines")
        print()

    if function_violations_all:
        has_issues = True
        print("[FAIL] FUNCTION SIZE VIOLATIONS (Limit: 30 lines):")
        for filepath, func, lines, start_line in sorted(function_violations_all, key=lambda x: x[2], reverse=True):
            print(f"  [FAIL {lines} lines] {filepath}:{start_line} -> Method `{func}`")
        print()

    if has_issues:
        print("[TIP] Teacher Tip: Keep your code modular! Split large widgets, controller logic, or endpoint handlers into dedicated smaller files.")
        if args.advisory:
            print("\n[SUCCESS] Verification completed with warnings. (Exited successfully due to --advisory)")
            sys.exit(0)
        else:
            print("\n[FAIL] Modularity verification failed. Please clean up the violations above.")
            sys.exit(1)
    else:
        print("[SUCCESS] All scanned files are modular! (Files under 350 lines, functions under 30 lines)")
        sys.exit(0)

if __name__ == "__main__":
    main()
