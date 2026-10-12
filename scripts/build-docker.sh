#!/usr/bin/env bash
# 构建并推送 ROS-Box 多架构 Docker 镜像
set -e

IMAGE_NAME=${1:-"ros-box:latest"}

echo "=========================================================="
echo "  Building Multi-Arch ROS-Box Container Image"
echo "  Target: linux/amd64, linux/arm64"
echo "  Tag:    $IMAGE_NAME"
echo "=========================================================="

# 确保启用了 Buildx
docker buildx create --use --name rosbox-builder 2>/dev/null || docker buildx use rosbox-builder

# 构建多架构镜像 (如果是推送到 registry，请追加 --push 参数)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "$IMAGE_NAME" \
  --load \
  .

echo "Build completed successfully: $IMAGE_NAME"
