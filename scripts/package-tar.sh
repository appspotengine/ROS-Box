#!/usr/bin/env bash
# 打包 ROS-Box 镜像为 RouterOS 离线导入专用的 .tar 文件
set -e

ARCH=${1:-"amd64"}

echo "=========================================================="
echo "  Exporting ROS-Box Container to RouterOS .tar"
echo "  Architecture: $ARCH (amd64 / arm64 / all)"
echo "=========================================================="

build_arch() {
  local target_arch=$1
  echo "[+] Building and exporting linux/$target_arch..."
  docker buildx build \
    --platform linux/$target_arch \
    -t ros-box:$target_arch \
    --output type=docker,dest=ROS-Box-$target_arch.tar \
    .
  echo "[✓] Successfully generated: ROS-Box-$target_arch.tar"
}

if [ "$ARCH" = "all" ]; then
  build_arch "amd64"
  build_arch "arm64"
else
  build_arch "$ARCH"
fi

echo "=========================================================="
echo "Packaging complete!"
echo "Upload the .tar file into your RouterOS external disk via WinBox Files."
echo "=========================================================="
