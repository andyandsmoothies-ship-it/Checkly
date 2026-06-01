import subprocess
import sys

# Reconfigure stdout to use UTF-8 to prevent charmap encoding errors
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

print("Running rtk flutter test...")
process = subprocess.Popen(
    "rtk flutter test --reporter=expanded",
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    encoding="utf-8",
    errors="ignore"
)

for line in iter(process.stdout.readline, ""):
    line_str = line.strip()
    if "loading" in line_str or line_str.startswith("+") or line_str.startswith("00:"):
        # This is a progress line
        pass
    else:
        try:
            print(line_str)
        except Exception as e:
            pass

process.stdout.close()
return_code = process.wait()
print(f"Finished with return code: {return_code}")
