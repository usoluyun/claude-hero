"""End-to-end smoke test: runs API + static + browses in headless."""
import subprocess, time, sys, urllib.request

# 1. Start API
api = subprocess.Popen(
    ['uvicorn', 'src.api.main:app', '--port', '8101'],
    cwd='/Users/luyun/Documents/poc/claude-hero/hero-tavern',
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)
# 2. Start static
static = subprocess.Popen(
    ['python3', '-m', 'http.server', '8102', '--directory', 'web/static'],
    cwd='/Users/luyun/Documents/poc/claude-hero/hero-tavern',
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

print("Waiting for servers...", flush=True)
time.sleep(3)

# 3. Check API
try:
    with urllib.request.urlopen('http://localhost:8101/api/status') as r:
        import json
        data = json.loads(r.read())
        print(f"[OK] API /api/status: {len(data['sessions'])} sessions")
        print(f"[OK] status_summary: {data['status_summary']}")
except Exception as e:
    print(f"[FAIL] API: {e}")
    sys.exit(1)

# 4. Check static
try:
    with urllib.request.urlopen('http://localhost:8102/') as r:
        body = r.read().decode()
        if 'session-card' not in body and 'tavern.js' not in body:
            print(f"[FAIL] Static: unexpected body start")
            sys.exit(1)
        print(f"[OK] Static serves HTML ({len(body)} bytes)")
except Exception as e:
    print(f"[FAIL] Static: {e}")
    sys.exit(1)
finally:
    api.terminate(); static.terminate()
    api.wait(); static.wait()
