import time, subprocess, urllib.request, sys

def check_rosbox_health():
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Starting ROS-Box Watchdog Probe...")
    healthy = True
    
    # 1. Probe HTTP endpoint
    try:
        req = urllib.request.Request("http://10.0.0.11:2026/", headers={"User-Agent": "ROSBoxWatchdog/1.0"})
        with urllib.request.urlopen(req, timeout=4) as resp:
            if resp.status == 200:
                print("  [OK] Web Panel HTTP 200 responsive.")
            else:
                print(f"  [WARN] Web Panel returned HTTP status {resp.status}")
                healthy = False
    except Exception as e:
        print(f"  [FAIL] Web Panel unreachable: {e}")
        healthy = False

    # 2. Check RouterOS Container status & Memory
    try:
        res = subprocess.run([
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=NUL",
            "zyy@10.0.0.1", "/container/print"
        ], capture_output=True, text=True, timeout=10)
        if "RUNNING" in res.stdout:
            print("  [OK] Container running on RouterOS.")
            for line in res.stdout.splitlines():
                if "open-box" in line or "RUNNING" in line:
                    print(f"       {line.strip()}")
        else:
            print("  [FAIL] Container is NOT running!")
            healthy = False
    except Exception as e:
        print(f"  [ERROR] SSH to RouterOS failed: {e}")
        healthy = False

    # 3. Autonomous Self-Healing if unhealthy
    if not healthy:
        print("  [ACTION] Initiating autonomous self-healing on RouterOS container...")
        restart_cmd = '/container/stop [find name="open-box-ros-amd64"]; :delay 3s; /container/start [find name="open-box-ros-amd64"]'
        r = subprocess.run([
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=NUL",
            "zyy@10.0.0.1", restart_cmd
        ], capture_output=True, text=True, timeout=15)
        print("  [ACTION] Restart trigger executed. Awaiting 5s for re-probe...")
        time.sleep(5)
        try:
            with urllib.request.urlopen("http://10.0.0.11:2026/", timeout=5) as resp:
                if resp.status == 200:
                    print("  [RECOVERED] Container successfully self-healed and online!")
        except Exception:
            print("  [ALERT] Container still recovering, will re-check next cycle.")
    else:
        print("  [STATUS] All ROS-Box services healthy and nominal.")

if __name__ == "__main__":
    check_rosbox_health()
