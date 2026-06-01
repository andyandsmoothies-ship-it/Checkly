import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('.agents/logs/full_flutter_test_output.log', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
print("=== FAILING TESTS ===")
for i, line in enumerate(lines):
    # Print progress lines showing when the failure count goes up
    # Wait, the failure count is the "-2" or "-1" part of "+371 -2:" or "+811 -2:"
    # Let's find where the count first went up, or lines containing "FAIL" or "Expected:"
    if "Expected:" in line or "Actual:" in line or "package:test" in line or "dart:async" in line:
        start = max(0, i - 10)
        end = min(len(lines), i + 10)
        print(f"\n--- Context around line {i+1} ---")
        for j in range(start, end):
            print(f"{j+1}: {lines[j].strip()}")
        print("--------------------------------")
