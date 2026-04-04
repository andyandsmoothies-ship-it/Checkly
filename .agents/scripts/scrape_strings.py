import os
import re
import json
import argparse
from pathlib import Path

def extract_strings_from_file(file_path):
    """
    Scans a Dart file for hardcoded strings inside Text(), SnackBar, and AlertDialog widgets.
    """
    results = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Regex to catch Text('something') or Text("something")
        # Handles basic interpolation conceptually by grabbing the whole string argument
        text_pattern = re.compile(r"Text\(\s*['\"](.*?)['\"]", re.DOTALL)
        
        # Regex to catch raw SnackBar content
        snackbar_pattern = re.compile(r"SnackBar\([^)]*content:\s*Text\(\s*['\"](.*?)['\"]", re.DOTALL)
        
        # Regex to catch AlertDialog titles or message
        dialog_title_pattern = re.compile(r"AlertDialog\([^)]*title:\s*const\s*Text\(\s*['\"](.*?)['\"]", re.DOTALL)
        dialog_content_pattern = re.compile(r"AlertDialog\([^)]*content:\s*Text\(\s*['\"](.*?)['\"]", re.DOTALL)

        for match in text_pattern.finditer(content):
            results.append({"type": "Text", "value": match.group(1).strip()})
        
        for match in snackbar_pattern.finditer(content):
            results.append({"type": "SnackBar", "value": match.group(1).strip()})
            
        for match in dialog_title_pattern.finditer(content):
            results.append({"type": "DialogTitle", "value": match.group(1).strip()})
            
        for match in dialog_content_pattern.finditer(content):
            results.append({"type": "DialogContent", "value": match.group(1).strip()})

    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        
    return results

def main():
    parser = argparse.ArgumentParser(description="Extract UI strings from Flutter codebase for Semantic Tone Auditing.")
    parser.add_argument('--dir', type=str, default='lib', help='Directory to scan (default: lib)')
    parser.add_argument('--out', type=str, default='ui_strings_export.json', help='Output JSON file')
    args = parser.parse_args()

    target_dir = Path(args.dir)
    if not target_dir.exists() or not target_dir.is_dir():
        print(f"Error: Directory {target_dir} not found.")
        return

    all_strings = {}
    total_files = 0
    total_strings = 0

    print(f"Scanning directory: {target_dir}...")

    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = Path(root) / file
                strings = extract_strings_from_file(file_path)
                if strings:
                    rel_path = str(file_path.relative_to(target_dir))
                    all_strings[rel_path] = strings
                    total_files += 1
                    total_strings += len(strings)

    # De-duplicate empty strings
    for file, items in list(all_strings.items()):
        valid_items = [i for i in items if i['value'] != '']
        if not valid_items:
            del all_strings[file]
        else:
            all_strings[file] = valid_items

    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(all_strings, f, indent=2)

    print(f"✅ Extraction Complete.")
    print(f"📊 Files scanned: {total_files}")
    print(f"📝 Strings extracted: {total_strings}")
    print(f"💾 Output saved to: {args.out}")

if __name__ == "__main__":
    main()
