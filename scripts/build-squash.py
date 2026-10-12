import os, sys, tarfile, hashlib, json, io, time, gzip, urllib.request

SRC_TAR = "d:/Downloads/open-box recreative/open-box-ros-amd64.tar"
OUT_TAR = "d:/Downloads/open-box recreative/ROS-Box.tar"
OUT_TAR_GZ = "d:/Downloads/open-box recreative/ROS-Box.tar.gz"

t0 = time.time()
print(f"Reading manifest from {SRC_TAR}...")
with tarfile.open(SRC_TAR, "r") as t:
    manifest_raw = t.extractfile("manifest.json").read().decode("utf-8")
    manifest = json.loads(manifest_raw)[0]
    config_name = manifest["Config"]
    layers = manifest["Layers"]
    config_raw = t.extractfile(config_name).read().decode("utf-8")
    orig_config = json.loads(config_raw)

    print(f"Found {len(layers)} layers. Merging in-memory...")
    fs = {}

    for idx, layer_rel in enumerate(layers):
        layer_file = t.extractfile(layer_rel)
        with tarfile.open(fileobj=layer_file, mode="r:*") as lt:
            for member in lt.getmembers():
                clean_name = member.name.lstrip("/")
                if clean_name.startswith("./"):
                    clean_name = clean_name[2:]
                base = os.path.basename(clean_name)
                
                # Check for whiteout
                if base.startswith(".wh."):
                    if base == ".wh..wh..opq":
                        parent = os.path.dirname(clean_name)
                        for k in list(fs.keys()):
                            if k.startswith(parent + "/") and k != parent:
                                del fs[k]
                    else:
                        target = base[4:]
                        target_path = os.path.join(os.path.dirname(clean_name), target).replace("\\", "/")
                        for k in list(fs.keys()):
                            if k == target_path or k.startswith(target_path + "/"):
                                del fs[k]
                    continue

                if member.isreg():
                    data = lt.extractfile(member).read()
                    fs[clean_name] = (member, data)
                else:
                    fs[clean_name] = (member, None)

print(f"Merge done in {time.time()-t0:.1f}s. Total entries: {len(fs)}")

# 1. Prune unneeded paths
prune_prefixes = [
    "usr/local/include",
    "usr/local/lib/node_modules/npm",
    "usr/local/share/man",
    "usr/local/share/doc",
    "usr/share/man",
    "usr/share/doc",
    "var/cache",
    "var/log",
    "root/.npm",
    "root/.cache",
]

for p in prune_prefixes:
    for k in list(fs.keys()):
        if k == p or k.startswith(p + "/"):
            del fs[k]

for b in ["npm", "npx", "corepack", "yarn"]:
    bp = f"usr/local/bin/{b}"
    if bp in fs:
        del fs[bp]

# Prune test files in server
for k in list(fs.keys()):
    if (k.startswith("opt/open-box/panel/server/") or k.startswith("opt/ROS-Box/panel/server/")) and (k.endswith(".test.mjs") or k.endswith(".test.js")):
        del fs[k]

print("Pruning complete.")

# 2. Rename all opt/open-box entries to opt/ROS-Box
print("Migrating base opt/open-box to opt/ROS-Box...")
migrated_fs = {}
for k, (member, data) in fs.items():
    if k == "opt/open-box":
        member.name = "opt/ROS-Box"
        migrated_fs["opt/ROS-Box"] = (member, data)
    elif k.startswith("opt/open-box/"):
        new_k = "opt/ROS-Box" + k[len("opt/open-box"):]
        member.name = new_k
        migrated_fs[new_k] = (member, data)
    else:
        migrated_fs[k] = (member, data)
fs = migrated_fs

# Add symlinks: opt/open-box and opt/ROS-Box -> /opt/ROS-Box
for link_name in ["opt/open-box"]:
    ti = tarfile.TarInfo(name=link_name)
    ti.type = tarfile.SYMTYPE
    ti.linkname = "/opt/ROS-Box"
    ti.mode = 0o777
    ti.mtime = int(time.time())
    fs[link_name] = (ti, None)

# 3. Inject latest customized files from workspace
def add_file(rel_path, local_path, mode=0o755):
    with open(local_path, "rb") as f:
        data = f.read()
    ti = tarfile.TarInfo(name=rel_path)
    ti.size = len(data)
    ti.mode = mode
    ti.mtime = int(time.time())
    ti.type = tarfile.REGTYPE
    ti.uid = 0
    ti.gid = 0
    ti.uname = "root"
    ti.gname = "root"
    fs[rel_path] = (ti, data)

def add_mem_file_to_fs(rel_path, data, mode=0o755):
    ti = tarfile.TarInfo(name=rel_path)
    ti.size = len(data)
    ti.mode = mode
    ti.mtime = int(time.time())
    ti.type = tarfile.REGTYPE
    ti.uid = 0
    ti.gid = 0
    ti.uname = "root"
    ti.gname = "root"
    fs[rel_path] = (ti, data)

def add_dir(rel_path, mode=0o755):
    if rel_path not in fs:
        ti = tarfile.TarInfo(name=rel_path)
        ti.mode = mode
        ti.mtime = int(time.time())
        ti.type = tarfile.DIRTYPE
        ti.uid = 0
        ti.gid = 0
        fs[rel_path] = (ti, None)

# Add dirs
for d in ["opt/ROS-Box", "opt/ROS-Box/container/bin", "opt/ROS-Box/container/shim", "etc/init.d", "etc/dropbear", "usr/bin", "usr/sbin"]:
    add_dir(d)

# Scripts
add_file("opt/ROS-Box/entrypoint.sh", "d:/Downloads/open-box recreative/entrypoint.sh", 0o755)
add_file("opt/ROS-Box/container/bin/openbox-ctl", "d:/Downloads/open-box recreative/container/bin/openbox-ctl", 0o755)
add_file("opt/ROS-Box/container/bin/openbox-panel-ctl", "d:/Downloads/open-box recreative/container/bin/openbox-panel-ctl", 0o755)
add_file("opt/ROS-Box/container/shim/uci", "d:/Downloads/open-box recreative/container/shim/uci", 0o755)
add_file("opt/ROS-Box/container/shim/logread", "d:/Downloads/open-box recreative/container/shim/logread", 0o755)
add_file("etc/init.d/openbox", "d:/Downloads/open-box recreative/container/bin/openbox-ctl", 0o755)
add_file("etc/init.d/rosbox", "d:/Downloads/open-box recreative/container/bin/openbox-ctl", 0o755)
add_file("usr/bin/uci", "d:/Downloads/open-box recreative/container/shim/uci", 0o755)

if os.path.exists("d:/Downloads/open-box recreative/meta.json"):
    add_file("opt/ROS-Box/meta.json", "d:/Downloads/open-box recreative/meta.json", 0o644)

# Sync panel/dist to opt/ROS-Box/panel/dist
dist_dir = "d:/Downloads/open-box recreative/panel/dist"
for root, dirs, files in os.walk(dist_dir):
    rel = os.path.relpath(root, dist_dir).replace("\\", "/")
    target_d = "opt/ROS-Box/panel/dist" if rel == "." else f"opt/ROS-Box/panel/dist/{rel}"
    add_dir(target_d)
    for f in files:
        full = os.path.join(root, f)
        target_f = f"{target_d}/{f}"
        add_file(target_f, full, 0o644)

# Sync panel/server to opt/ROS-Box/panel/server
server_dir = "d:/Downloads/open-box recreative/panel/server"
for root, dirs, files in os.walk(server_dir):
    rel = os.path.relpath(root, server_dir).replace("\\", "/")
    target_d = "opt/ROS-Box/panel/server" if rel == "." else f"opt/ROS-Box/panel/server/{rel}"
    add_dir(target_d)
    for f in files:
        if f.endswith(".test.mjs") or f.endswith(".test.js"):
            continue
        full = os.path.join(root, f)
        target_f = f"{target_d}/{f}"
        add_file(target_f, full, 0o644 if not f.endswith(".sh") else 0o755)

# 4. Inject dropbear package binaries (for guaranteed offline SSH terminal daemon)
print("Injecting dropbear SSH binaries...")
dropbear_apk_url = "https://mirrors.aliyun.com/alpine/v3.21/main/x86_64/dropbear-2024.86-r0.apk"
dropbear_cache = "d:/Downloads/open-box recreative/scratch/dropbear-2024.86-r0.apk"
os.makedirs(os.path.dirname(dropbear_cache), exist_ok=True)
if not os.path.exists(dropbear_cache):
    print("Downloading dropbear apk from Aliyun mirror...")
    req = urllib.request.urlopen(dropbear_apk_url, timeout=30)
    with open(dropbear_cache, "wb") as f_apk:
        f_apk.write(req.read())

with tarfile.open(dropbear_cache, mode="r:gz") as apk_t:
    for m in apk_t.getmembers():
        if m.name in ["usr/sbin/dropbear", "usr/bin/dropbearkey"]:
            content = apk_t.extractfile(m).read()
            add_mem_file_to_fs(m.name, content, 0o755)
            print(f"  Added {m.name} ({len(content)} bytes)")

# Dropbear symlink in usr/bin
ti_db = tarfile.TarInfo(name="usr/bin/dropbear")
ti_db.type = tarfile.SYMTYPE
ti_db.linkname = "/usr/sbin/dropbear"
ti_db.mode = 0o777
ti_db.mtime = int(time.time())
fs["usr/bin/dropbear"] = (ti_db, None)

# Ensure critical symlinks exist
for link_name, target in [("bin/sh", "/bin/busybox"), ("bin/ash", "/bin/busybox")]:
    ti = tarfile.TarInfo(name=link_name)
    ti.type = tarfile.SYMTYPE
    ti.linkname = target
    ti.mode = 0o777
    ti.mtime = int(time.time())
    fs[link_name] = (ti, None)

# Ensure busybox is 0755
if "bin/busybox" in fs:
    m, d = fs["bin/busybox"]
    m.mode = 0o755
    m.type = tarfile.REGTYPE
    fs["bin/busybox"] = (m, d)

print(f"Custom files injected. Total final entries: {len(fs)}")

# 5. Create single layer tar in memory / buffer
print("Packaging single layer tar...")
layer_io = io.BytesIO()
with tarfile.open(fileobj=layer_io, mode="w") as lt:
    for name in sorted(fs.keys()):
        member, data = fs[name]
        if member.isreg() and data is not None:
            member.size = len(data)
            lt.addfile(member, io.BytesIO(data))
        else:
            member.size = 0
            lt.addfile(member)

layer_bytes = layer_io.getvalue()
layer_sha256 = hashlib.sha256(layer_bytes).hexdigest()
diff_id = f"sha256:{layer_sha256}"
print(f"Single layer tar created! Size: {len(layer_bytes)/1024/1024:.2f} MB, Digest: {layer_sha256[:16]}...")

# 6. Create single layer Docker config JSON
orig_config["rootfs"]["diff_ids"] = [diff_id]
orig_config["history"] = [
    {
        "created": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "created_by": "ROS-Box RouterOS Appliance <https://github.com/open-box/open-box>",
        "comment": "Squashed single layer ROS-Box RouterOS container"
    }
]
orig_config["config"]["Entrypoint"] = ["/opt/ROS-Box/entrypoint.sh"]
orig_config["config"]["Cmd"] = []
orig_config["config"]["WorkingDir"] = "/opt/ROS-Box"
orig_config["config"]["Volumes"] = {
    "/opt/ROS-Box/data": {},
    "/opt/ROS-Box/etc": {}
}

config_bytes = json.dumps(orig_config, indent=2).encode("utf-8")
config_sha256 = hashlib.sha256(config_bytes).hexdigest()
config_blob_name = f"blobs/sha256/{config_sha256}"

# 7. Create OCI manifest blob
oci_manifest = {
    "schemaVersion": 2,
    "mediaType": "application/vnd.oci.image.manifest.v1+json",
    "config": {
        "mediaType": "application/vnd.oci.image.config.v1+json",
        "digest": f"sha256:{config_sha256}",
        "size": len(config_bytes)
    },
    "layers": [
        {
            "mediaType": "application/vnd.oci.image.layer.v1.tar",
            "digest": f"sha256:{layer_sha256}",
            "size": len(layer_bytes)
        }
    ]
}
oci_manifest_bytes = json.dumps(oci_manifest, indent=2).encode("utf-8")
oci_manifest_sha256 = hashlib.sha256(oci_manifest_bytes).hexdigest()
oci_manifest_blob_name = f"blobs/sha256/{oci_manifest_sha256}"

# 8. Create index.json
oci_index = {
    "schemaVersion": 2,
    "mediaType": "application/vnd.oci.image.index.v1+json",
    "manifests": [
        {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": f"sha256:{oci_manifest_sha256}",
            "size": len(oci_manifest_bytes),
            "annotations": {
                "io.containerd.image.name": "docker.io/library/ROS-Box:latest",
                "org.opencontainers.image.ref.name": "latest"
            }
        }
    ]
}
oci_index_bytes = json.dumps(oci_index, indent=2).encode("utf-8")

# 9. Create Docker manifest.json with LayerSources
docker_manifest = [
    {
        "Config": config_blob_name,
        "RepoTags": [
            "ROS-Box:latest",
            "ros-box:amd64",
            "open-box-ros:amd64"
        ],
        "Layers": [
            f"blobs/sha256/{layer_sha256}"
        ],
        "LayerSources": {
            f"sha256:{layer_sha256}": {
                "mediaType": "application/vnd.oci.image.layer.v1.tar",
                "size": len(layer_bytes),
                "digest": f"sha256:{layer_sha256}"
            }
        }
    }
]
docker_manifest_bytes = json.dumps(docker_manifest, indent=2).encode("utf-8")

# 10. Create oci-layout and repositories
oci_layout_bytes = json.dumps({"imageLayoutVersion": "1.0.0"}).encode("utf-8")
repositories_bytes = json.dumps({
    "ROS-Box": {"latest": layer_sha256},
    "open-box-ros": {"amd64": layer_sha256}
}).encode("utf-8")

# 11. Create final ROS-Box.tar
print(f"Writing final Docker/OCI image: {OUT_TAR}...")
with tarfile.open(OUT_TAR, "w") as ot:
    def add_mem_file(name, b, mode=0o644):
        ti = tarfile.TarInfo(name=name)
        ti.size = len(b)
        ti.mtime = int(time.time())
        ti.mode = mode
        ti.type = tarfile.REGTYPE
        ot.addfile(ti, io.BytesIO(b))

    def add_mem_dir(name, mode=0o755):
        ti = tarfile.TarInfo(name=name)
        ti.size = 0
        ti.mtime = int(time.time())
        ti.mode = mode
        ti.type = tarfile.DIRTYPE
        ot.addfile(ti)

    # Directories
    add_mem_dir("blobs")
    add_mem_dir("blobs/sha256")

    # Blobs
    add_mem_file(config_blob_name, config_bytes)
    add_mem_file(oci_manifest_blob_name, oci_manifest_bytes)
    add_mem_file(f"blobs/sha256/{layer_sha256}", layer_bytes)

    # Metadata files
    add_mem_file("index.json", oci_index_bytes)
    add_mem_file("manifest.json", docker_manifest_bytes)
    add_mem_file("oci-layout", oci_layout_bytes)
    add_mem_file("repositories", repositories_bytes)

tar_size = os.path.getsize(OUT_TAR) / 1024 / 1024
print(f"ROS-Box.tar created successfully! Size: {tar_size:.2f} MB")

# 12. Create ROS-Box.tar.gz
print("Compressing to ROS-Box.tar.gz...")
with open(OUT_TAR, "rb") as f_in, gzip.open(OUT_TAR_GZ, "wb", compresslevel=6) as f_out:
    while chunk := f_in.read(1024*1024*4):
        f_out.write(chunk)

gz_size = os.path.getsize(OUT_TAR_GZ) / 1024 / 1024
print(f"ROS-Box.tar.gz created! Size: {gz_size:.2f} MB")
print(f"Build complete in {time.time()-t0:.1f}s!")
