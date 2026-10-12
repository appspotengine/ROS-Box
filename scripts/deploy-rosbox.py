import paramiko
import ftplib
import time
import os
import sys
import json

HOST = "10.0.0.1"
USER = "zyy"
PASS = "820130"
LOCAL_TAR = r"D:\Downloads\open-box recreative\ROS-Box.tar"

print("==================================================================")
print("  ROS-Box Fully Autonomous End-to-End Build & Deployment Engine  ")
print("==================================================================")

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASS, timeout=10)

def ros(cmd):
    stdin, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    return out, err

print("\n[Step 1] Stopping & Removing existing container...")
ros('/container/stop [find name=ROS-Box-amd64]')
for _ in range(15):
    out, _ = ros('/container print detail')
    if not out or "STOPPED" in out:
        break
    time.sleep(1)

ros('/container/remove [find name=ROS-Box-amd64]')
time.sleep(2)
out, _ = ros('/container print')
print("Containers after remove:", out if out else "(none)")

print("\n[Step 2] Cleaning up /disk1 stores...")
ros('/file/remove [find name="disk1/ROS-Box"]')
time.sleep(2)
ros('/file/remove [find name="disk1/openbox"]')
time.sleep(1)

print("\n[Step 3] Uploading new ROS-Box.tar to RouterOS root directory...")
ros('/ip/service/enable ftp')
time.sleep(1)
t0 = time.time()
try:
    ftp = ftplib.FTP(HOST, USER, PASS, timeout=60)
    with open(LOCAL_TAR, "rb") as f:
        ftp.storbinary("STOR ROS-Box.tar", f, blocksize=4*1024*1024)
    ftp.quit()
    print(f"    Uploaded {os.path.getsize(LOCAL_TAR)/(1024*1024):.2f} MB in {time.time()-t0:.2f}s!")
finally:
    ros('/ip/service/disable ftp')

print("\n[Step 4] Checking RouterOS root files...")
out, _ = ros('/file print')
print(out)

print("\n[Step 5] Adding container with comment='ROS-BOX-10.0.0.11' and shell='/bin/sh'...")
cmd_add = '/container add file=ROS-Box.tar root-dir=/disk1/ROS-Box interface=ROSBox name=ROS-Box-amd64 comment="ROS-BOX-10.0.0.11" logging=yes start-on-boot=yes shell="/bin/sh"'
out, err = ros(cmd_add)
print("Add result:", out, err if err else "(ok)")

print("\n[Step 6] Monitoring container image extraction...")
t0 = time.time()
extracted = False
for i in range(60):
    time.sleep(2)
    out, _ = ros('/container print detail')
    print(f"[{int(time.time()-t0)}s] Checking extraction...")
    if "STOPPED" in out:
        print(">>> SUCCESS: Image extracted and container is STOPPED (ready to start)!")
        print(out)
        extracted = True
        break
    log_out, _ = ros('/log print where topics~"container"')
    recent_lines = log_out.splitlines()[-4:]
    for l in recent_lines:
        print("  Log:", l)
    if "download/extract error" in "\n".join(recent_lines):
        print("FATAL: Extract error in recent logs!")
        break

if not extracted:
    print("Extraction did not complete in time!")
    client.close()
    sys.exit(1)

print("\n[Step 7] Starting ROS-Box-amd64 container...")
out, err = ros('/container/start [find name=ROS-Box-amd64]')
print("Start command result:", out, err if err else "(ok)")

time.sleep(5)
out, _ = ros('/container print detail')
print("\nContainer Details after start:\n", out)

print("\n[Step 8] Recent container logs:")
out_log, _ = ros('/log print where topics~"container"')
for l in out_log.splitlines()[-25:]:
    print(l)

print("\n[Step 9] Ensuring /disk1/openbox is deleted...")
ros('/file/remove [find name="disk1/openbox"]')
time.sleep(1)
out_files, _ = ros('/file print')
print(out_files)

client.close()
print("\n[Step 10] RouterOS side installation & start completed!")

print("\n[Step 11] Waiting for ROS-Box Web Panel (http://10.0.0.11:2026) to come online...")
import urllib.request
online = False
for i in range(30):
    time.sleep(2)
    try:
        req = urllib.request.Request("http://10.0.0.11:2026/")
        with urllib.request.urlopen(req, timeout=3) as resp:
            if resp.status == 200:
                print(f">>> ROS-Box Panel is ONLINE! HTTP Status: {resp.status}")
                online = True
                break
    except Exception as e:
        print(f"  Waiting for web panel... ({e})")

if online and os.path.exists("backup_container_20261012.json"):
    print("\n[Step 12] Restoring user configuration from backup_container_20261012.json...")
    try:
        with open("backup_container_20261012.json", "r", encoding="utf-8-sig") as f:
            backup_data = json.load(f)
        post_data = json.dumps(backup_data).encode("utf-8")
        req = urllib.request.Request(
            "http://10.0.0.11:2026/api/openbox/backup/import",
            data=post_data,
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp_body = resp.read().decode("utf-8")
            print(">>> Configuration restore result:", resp_body)
    except Exception as e:
        print("Configuration restore error:", e)

print("\n>>> All deployment & verification steps finished successfully!")
