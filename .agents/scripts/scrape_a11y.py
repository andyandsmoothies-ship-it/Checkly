import os
import re
import json
import argparse
from pathlib import Path

def scan_dart_files(directory):
    violations = []
    
    # Regex patterns for bad practices
    # 1. Hardcoded colors (e.g. Colors.red, Colors.blueAccent)
    color_pattern = re.compile(r'\b(?:Colors|CupertinoColors)\.[a-zA-Z0-9_]+\b|Color\([^\)]+\)')
    # 2. Hardcoded fonts
    font_pattern = re.compile(r'fontSize:\s*([0-9]+\.?[0-9]*)')
    
    # Acceptable structural color defaults that can bypass warnings
    whitelisted_colors = [
        'Colors.transparent', 
        'Colors.white', 
        'Colors.black',
        'Colors.grey' # Often used for subtle divides, though borderline
    ]
    
    for path in Path(directory).rglob('*.dart'):
        path_str = str(path)
        # Skip generated and test files
        if 'test' in path_str or '.g.dart' in path_str or '.freezed.dart' in path_str:
            continue
            
        try:
            with open(path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                
            for i, line in enumerate(lines):
                line_idx = i + 1
                
                # Check for Color violations
                for match in color_pattern.finditer(line):
                    matched_str = match.group()
                    if any(w in matched_str for w in whitelisted_colors):
                        continue
                        
                    violations.append({
                        "file": path_str,
                        "line": line_idx,
                        "type": "Design System Violation",
                        "severity": "High",
                        "detail": f"Hardcoded color detected: `{matched_str}`. Must use Theme.of(context).colorScheme."
                    })
                    
                # Check for Font violations
                for match in font_pattern.finditer(line):
                    matched_str = match.group(1)
                    violations.append({
                        "file": path_str,
                        "line": line_idx,
                        "type": "Typography Violation",
                        "severity": "Medium",
                        "detail": f"Hardcoded fontSize detected: `{matched_str}`. Must use Theme.of(context).textTheme."
                    })
                    
        except Exception as e:
            pass
            
    return violations

def main():
    parser = argparse.ArgumentParser(description="Deterministic parser for finding hardcoded design tokens.")
    parser.add_argument("--dir", required=True, help="Directory to scan (e.g., lib/)")
    parser.add_argument("--out", required=True, help="Output JSON path")
    args = parser.parse_args()
    
    results = scan_dart_files(args.dir)
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)

    print(f"Sweep complete. Found {len(results)} violations. Results saved to {args.out}")

if __name__ == "__main__":
    main()
