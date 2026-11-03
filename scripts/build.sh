#!/usr/bin/env bash
# 编译 xiaohongshu-mcp 与登录工具。
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

cd "$REPO"
mkdir -p bin

# 国内网络走 goproxy.cn；只对本次命令生效，不改全局配置。
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"

echo "==> go mod download"
go mod download

echo "==> build xiaohongshu-mcp"
go build -trimpath -ldflags "-s -w -X main.version=dev-local" -o bin/xiaohongshu-mcp .

echo "==> build xiaohongshu-login"
go build -trimpath -ldflags "-s -w" -o bin/xiaohongshu-login ./cmd/login

ls -lh bin/
