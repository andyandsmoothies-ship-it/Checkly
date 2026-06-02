import sys
import re

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

# Let's search for when the failure count increments
# Format in standard reporter: "00:05 +34 -1: ..."
pattern = re.compile(r'^\d\d:\d\d \+(\d+) -(\d+):')

prev_failures = 0
first_fail_indices = []

for i, line in enumerate(lines):
    match = pattern.match(line)
    if match:
        success_count = int(match.group(1))
        fail_count = int(match.group(2))
        if fail_count > prev_failures:
            print(f"Failure count went from {prev_failures} to {fail_count} at line {i+1}: {line}")
            first_fail_indices.append((prev_failures, fail_count, i))
            prev_failures = fail_count

# Now, let's find the error stack trace.
# Usually, before the failure count increments, there's a big error block.
# Let's search back from each of the first_fail_indices to print the actual error text!
for prev, current, idx in first_fail_indices:
    print(f"\n=======================================================")
    print(f"ERROR DETAILS FOR FAILURE #{current}:")
    print(f"=======================================================")
    # Print lines BEFORE this progress line that contain the error message
    # Let's find the preceding 30 lines and scan for errors or just print them
    start = max(0, idx - 40)
    end = min(len(lines), idx + 2)
    for j in range(start, end):
        print(f"{j+1}: {lines[j]}")
