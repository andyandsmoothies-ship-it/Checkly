import os
import re

lib_dir = "c:\\Users\\HP\\Documents\\GitHub\\Checkly\\lib"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    # Replace charcoal with theme color
    content = re.sub(r'AppTheme\.charcoal(?!\w)', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'AppColors\.charcoal(?!\w)', 'Theme.of(context).colorScheme.onSurface', content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

for root, _, files in os.walk(lib_dir):
    for fn in files:
        if fn.endswith('.dart') and fn not in ['app_theme.dart', 'app_colors.dart']:
            process_file(os.path.join(root, fn))

print("Refactor complete.")
