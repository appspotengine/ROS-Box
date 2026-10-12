# syntax=docker/dockerfile:1
FROM --platform=$TARGETPLATFORM node:22-alpine AS runtime

ARG TARGETARCH

# 安装运行环境与网络管理依赖 (iptables, nftables, iproute2, ca-certificates, tzdata 等)
RUN apk add --no-cache \
    iptables \
    nftables \
    iproute2 \
    curl \
    ca-certificates \
    tzdata \
    procps

WORKDIR /opt/open-box

# 复制面板静态资源与服务端代码
COPY panel/ /opt/open-box/panel/

# 复制根据构建架构匹配的 sing-box 二进制
COPY bin/${TARGETARCH}/sing-box /opt/open-box/bin/sing-box

# 复制容器管理脚本与 entrypoint
COPY container/ /opt/open-box/container/
COPY entrypoint.sh /opt/open-box/entrypoint.sh
COPY meta.json /opt/open-box/meta.json

# 安装服务端 Node.js 依赖 (使用 npm 生产安装，避免 pnpm 软链接兼容性问题)
RUN cd /opt/open-box/panel/server && \
    npm install --omit=dev --no-audit --no-fund && \
    chmod +x /opt/open-box/bin/sing-box \
             /opt/open-box/entrypoint.sh \
             /opt/open-box/container/bin/* \
             /opt/open-box/container/shim/*

# 创建持久化目录
RUN mkdir -p /opt/open-box/data /opt/open-box/etc

# 默认面板端口为 2026，DNS 为 7853
EXPOSE 2026 7853/udp 7853/tcp 7890

# 数据持久化卷
VOLUME ["/opt/open-box/data", "/opt/open-box/etc"]

ENTRYPOINT ["/opt/open-box/entrypoint.sh"]
