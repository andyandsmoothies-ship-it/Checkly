import sys
content = open('.agents/logs/test_run.log', 'rb').read()
# Decode from utf-16-le
try:
    decoded = content.decode('utf-16')
except Exception:
    decoded = content.decode('utf-8', errors='ignore')
open('.agents/logs/test_run_utf8.log', 'w', encoding='utf-8').write(decoded)
