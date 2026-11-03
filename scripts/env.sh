#!/usr/bin/env bash
# 公共环境变量。所有脚本 source 它。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$ROOT/xiaohongshu-mcp"
BIN="$REPO/bin"

PORT="${PORT:-18060}"
COOKIES_PATH="$ROOT/data/cookies.json"
MCP_LOG="$ROOT/logs/mcp.log"
PID_FILE="$ROOT/data/mcp.pid"

# 服务与登录工具必须共用同一个 HOME，cookies 与会话 seed 才能对上。
export COOKIES_PATH
export HOME="$ROOT/data/home"
export XDG_CACHE_HOME="$HOME/.cache"

mkdir -p "$ROOT/data" "$HOME" "$ROOT/logs"

# 读取 PID，进程不存在则输出空
mcp_pid() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "$pid"
      return 0
    fi
  fi
  return 1
}

mcp_ready() {
  curl -sS --max-time 3 -o /dev/null -X POST "http://127.0.0.1:$PORT/mcp" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"ping","version":"1"}}}' 2>/dev/null
}

# 平台探测（linux / wsl / darwin）
source "$ROOT/scripts/_platform.sh"
