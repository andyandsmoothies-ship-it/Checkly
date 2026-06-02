import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Try UTF-16 first, fallback to UTF-8
try:
    with open('.agents/logs/test_results.log', 'r', encoding='utf-16') as f:
        content = f.read()
    print("Successfully decoded with UTF-16")
except Exception as e:
    print(f"UTF-16 read failed ({e}), trying UTF-8...")
    with open('.agents/logs/test_results.log', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

lines = content.splitlines()
print(f"Total lines in log: {len(lines)}")

# Print lines containing failure summaries or detailed errors
failures = []
in_error = False
current_error = []

for i, line in enumerate(lines):
    # Detect the standard flutter test failures
    if " Expected:" in line or "  Expected:" in line or "Actual:" in line or "  Actual:" in line or "TestFailure" in line or "package:test" in line or "package:flutter_test" in line:
        failures.append((i, line))

print(f"Found {len(failures)} lines containing failure-related tokens.")

# Let's print the entire log sections where tests failed.
# To do this, we can search for the lines where "-3" or similar is printed, or find lines that start with "  " but not "+" or "00:".
# Actually, let's print all lines that don't match the standard status progress if they have the error indicator.
print("=== FAILING TESTS DETAIL ===")
for idx, line in failures[:50]:
    start = max(0, idx - 15)
    end = min(len(lines), idx + 15)
    print(f"\n--- Line {idx+1} (Context {start+1} to {end+1}) ---")
    for j in range(start, end):
        print(f"{j+1}: {lines[j]}")
