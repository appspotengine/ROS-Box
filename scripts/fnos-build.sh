#!/usr/bin/env bash
# 飞牛 OS (fnOS) / Linux Docker 一键构建并导出 RouterOS .tar 离线包
set -e

echo "=========================================================="
echo "  飞牛 OS (fnOS) - Open-Box 镜像构建与导出脚本"
echo "  架构: x86_64 (amd64)"
echo "=========================================================="

IMAGE_TAG="open-box-ros:amd64"
OUTPUT_TAR="open-box-ros-amd64.tar"

# 1. 本地构建 Docker 镜像 (飞牛为 x86_64 原生环境，构建极快)
echo "[1/2] 正在构建 Docker 镜像: $IMAGE_TAG ..."
docker build -t "$IMAGE_TAG" .

# 2. 导出为 RouterOS 标准 .tar 归档
echo "[2/2] 正在导出为 RouterOS 离线包: $OUTPUT_TAR ..."
docker save -o "$OUTPUT_TAR" "$IMAGE_TAG"

echo "=========================================================="
echo "  构建与导出完成！"
echo "  输出文件: $(pwd)/$OUTPUT_TAR"
echo "  大小: $(ls -lh "$OUTPUT_TAR" | awk '{print $5}')"
echo "=========================================================="
echo "您现在可以在飞牛的文件管理器中直接下载 $OUTPUT_TAR，"
echo "然后将其拖入 RouterOS 的 WinBox Files 窗口中进行安装！"
