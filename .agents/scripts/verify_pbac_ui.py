import os
import re
import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description="Verify PBAC compliance in Flutter widgets.")
    parser.add_argument(
        "--advisory",
        action="store_true",
        help="Run in advisory mode. Prints warnings but always exits with code 0."
    )
    return parser.parse_args()

def show_educational_tip(violation_type):
    print("\n[TIP] Friendly Teacher Tip:")
    if violation_type == "fab":
        print("  To protect a FloatingActionButton with permissions, wrap it in a 'PermissionGuard':")
        print("  ```dart")
        print("  floatingActionButton: PermissionGuard(")
        print("    capability: Capabilities.createSubmission,")
        print("    child: FloatingActionButton(")
        print("      onPressed: _submit,")
        print("      child: Icon(Icons.add),")
        print("    ),")
        print("  )")
        print("  ```")
    elif violation_type == "admin_button":
        print("  Administrative actions must check permissions or entity capability lists.")
        print("  Wrap your button in an 'ActionGuard' or 'PermissionGuard':")
        print("  ```dart")
        print("  ActionGuard(")
        print("    action: 'edit',")
        print("    allowedActions: submission.allowedActions,")
        print("    child: ElevatedButton(")
        print("      onPressed: _save,")
        print("      child: Text('Save'),")
        print("    ),")
        print("  )")
        print("  ```")
    print("  If this is a false positive, you can skip this file by adding this comment at the top:")
    print("  `// ignore_for_file: pbac_fab` or `// ignore_for_file: pbac_admin`")

def main():
    args = get_args()
    
    workspace_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    lib_dir = os.path.join(workspace_root, 'lib', 'features')
    
    # Pattern 1: Unprotected FABs
    # Finds floatingActionButton: <Widget> where <Widget> is NOT PermissionGuard, ChecklyFab, null, or a local boolean checker variable
    fab_pattern = re.compile(
        r'floatingActionButton:\s*(?!(PermissionGuard|ChecklyFab|null|can[A-Z]\w*|_can[A-Z]\w*|has[A-Z]\w*|_has[A-Z]\w*))\w+'
    )
    
    # Pattern 2: Action buttons in admin/pages that lack proper guard wrappers
    # We look for ElevatedButton, BubblyButton, or IconButton with destructive/mutative action names without wrapping guards
    admin_btn_pattern = re.compile(
        r'(ElevatedButton|BubblyButton|IconButton|TextButton)\(\s*([^)]*?onPressed:\s*(?!(null|_close|_cancel|can[A-Z]\w*|_can[A-Z]\w*|has[A-Z]\w*|_has[A-Z]\w*)).*?)\)',
        re.DOTALL
    )
    
    fab_violations = []
    admin_violations = []
    
    if not os.path.exists(lib_dir):
        print(f"Directory not found: {lib_dir}")
        sys.exit(0)
        
    for root, _, files in os.walk(lib_dir):
        is_admin_dir = "admin" in root
        
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                rel_path = os.path.relpath(filepath, workspace_root)
                
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    # Check file level ignore comments
                    ignore_fab = '// ignore_for_file: pbac_fab' in content
                    ignore_admin = '// ignore_for_file: pbac_admin' in content
                    
                    # 1. Verify FloatingActionButtons
                    if not ignore_fab:
                        for match in fab_pattern.finditer(content):
                            line_num = content.count('\n', 0, match.start()) + 1
                            snippet = match.group().strip()
                            fab_violations.append((rel_path, line_num, snippet))
                            
                    # 2. Verify Admin-specific page mutation buttons
                    if is_admin_dir and not ignore_admin:
                        # Only scan files in the 'pages' subfolder of admin
                        if "pages" in root:
                            for match in admin_btn_pattern.finditer(content):
                                # Check if it's in a guarded context
                                block_start = match.start()
                                # Quick heuristic check: is there a PermissionGuard or ActionGuard nearby above the button?
                                preceding_context = content[max(0, block_start-400):block_start]
                                if "PermissionGuard" not in preceding_context and "ActionGuard" not in preceding_context:
                                    line_num = content.count('\n', 0, block_start) + 1
                                    snippet = match.group(1) + "(... onPressed: ...)"
                                    admin_violations.append((rel_path, line_num, snippet))

    # Print results
    has_issues = False
    
    if fab_violations:
        has_issues = True
        print("\n[ERROR] Unprotected FloatingActionButtons Found:")
        for file, line, snippet in fab_violations:
            print(f"   - {file}:{line} -> `{snippet}`")
        show_educational_tip("fab")
        
    if admin_violations:
        has_issues = True
        print("\n[ERROR] Unprotected Admin Action Buttons Found:")
        for file, line, snippet in admin_violations:
            print(f"   - {file}:{line} -> `{snippet}`")
        show_educational_tip("admin_button")

    if has_issues:
        if args.advisory:
            print("\n[WARNING] PBAC UI Verification completed with warnings. (Exiting with success due to --advisory)")
            sys.exit(0)
        else:
            print("\n[FAIL] PBAC UI Verification Failed. Please protect these controls or resolve the issues above.")
            sys.exit(1)
    else:
        print("\n[SUCCESS] PBAC UI Verification Passed: All mapped action and floating controls are securely guarded.")
        sys.exit(0)

if __name__ == "__main__":
    main()
