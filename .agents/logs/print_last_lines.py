import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('.agents/logs/full_flutter_test_output.log', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
# Print any line that contains "Some tests failed" and also search for any failure/error messages
print("=== LAST 150 LINES ===")
for line in lines[-150:]:
    print(line.strip())

print("=== LINES CONTAINING 'fail' or 'error' (case-insensitive) ===")
for i, line in enumerate(lines):
    l = line.lower()
    if "fail" in l or "error" in l or "exception" in l:
        if not ("loading" in l or l.startswith("+") or l.startswith("00:")):
            print(f"Line {i+1}: {line.strip()}")
