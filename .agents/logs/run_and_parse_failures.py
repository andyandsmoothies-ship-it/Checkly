import subprocess
import sys

# Reconfigure stdout to use UTF-8 to prevent charmap encoding errors
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

print("Running rtk flutter test...")
process = subprocess.Popen(
    "rtk flutter test",
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    encoding="utf-8",
    errors="ignore"
)

full_output = []
for line in iter(process.stdout.readline, ""):
    full_output.append(line)

process.stdout.close()
return_code = process.wait()

# Save the full output to a UTF-8 log file
with open('.agents/logs/full_flutter_test_output.log', 'w', encoding='utf-8') as f:
    f.writelines(full_output)

# Parse output for failing tests and print details
print("=== PARSING FAILURE DETAILS ===")
in_failure = False
failure_lines = []

for line in full_output:
    line_strip = line.strip()
    if "Some tests failed" in line_strip:
        print(line_strip)
    # Check if a test failed
    if "  - " in line and " [X] " in line:
        print(line_strip)
    # Or in standard reporter
    if line.startswith("  - ") or "Expected:" in line or "Actual:" in line or "▼" in line:
        print(line_strip)

print(f"Finished with return code: {return_code}")
