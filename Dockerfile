# syntax=docker/dockerfile:1
FROM --platform=$TARGETPLATFORM node:22-alpine AS runtime

ARG TARGETARCH

# 安装运行环境与网络管理依赖 (iptables, nftables, iproute2, dropbear, ca-certificates, tzdata 等)
RUN apk add --no-cache \
    iptables \
    nftables \
    iproute2 \
    curl \
    ca-certificates \
    tzdata \
    procps \
    dropbear && \
    mkdir -p /etc/init.d /etc/dropbear

WORKDIR /opt/ROS-Box

# 复制面板静态资源与服务端代码
COPY panel/ /opt/ROS-Box/panel/

# 复制根据构建架构匹配的 sing-box 二进制
COPY bin/${TARGETARCH}/sing-box /opt/ROS-Box/bin/sing-box

# 复制容器管理脚本与 entrypoint
COPY container/ /opt/ROS-Box/container/
COPY entrypoint.sh /opt/ROS-Box/entrypoint.sh
COPY meta.json /opt/ROS-Box/meta.json

# 兼容软链接、系统服务脚本、依赖安装与冗余裁剪
RUN ln -sf /opt/ROS-Box /opt/open-box && \
    cp /opt/ROS-Box/container/bin/openbox-ctl /etc/init.d/openbox && \
    cp /opt/ROS-Box/container/bin/openbox-ctl /etc/init.d/rosbox && \
    cp /opt/ROS-Box/container/shim/uci /usr/bin/uci && \
    cd /opt/ROS-Box/panel/server && \
    npm install --omit=dev --no-audit --no-fund && \
    find /opt/ROS-Box/panel/server -maxdepth 3 -name "*.test.mjs" -delete && \
    chmod +x /opt/ROS-Box/bin/sing-box \
             /opt/ROS-Box/entrypoint.sh \
             /opt/ROS-Box/container/bin/* \
             /opt/ROS-Box/container/shim/* \
             /etc/init.d/openbox \
             /etc/init.d/rosbox \
             /usr/bin/uci && \
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/include \
           /usr/local/share/man \
           /usr/local/share/doc \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /usr/local/bin/corepack \
           /usr/local/bin/yarn \
           /root/.npm \
           /root/.cache \
           /var/cache/apk/*

# 创建持久化目录
RUN mkdir -p /opt/ROS-Box/data /opt/ROS-Box/etc

# 默认面板端口为 2026，DNS 为 7853
EXPOSE 2026 7853/udp 7853/tcp 7890

# 数据持久化卷
VOLUME ["/opt/ROS-Box/data", "/opt/ROS-Box/etc"]

ENTRYPOINT ["/opt/ROS-Box/entrypoint.sh"]
