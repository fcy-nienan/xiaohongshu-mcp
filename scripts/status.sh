#!/usr/bin/env bash
# 查看服务与登录状态。
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

echo "== 进程 =="
if pid="$(mcp_pid)"; then
  echo "running (pid=$pid), 端口 $PORT"
else
  echo "not running"
fi

echo "== 端口 =="
ss -ltn 2>/dev/null | grep -E ":$PORT\b" || echo "端口未监听"

echo "== MCP 握手 =="
curl -sS --max-time 5 -X POST "http://127.0.0.1:$PORT/mcp" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"status","version":"1"}}}' \
  ${AUTH_TOKEN:+-H "Authorization: Bearer $AUTH_TOKEN"} | head -c 500 || true
echo

echo "== cookies =="
if [[ -f "$COOKIES_PATH" ]]; then
  echo "$COOKIES_PATH ($(stat -c%s "$COOKIES_PATH") bytes, 修改时间 $(stat -c%y "$COOKIES_PATH"))"
else
  echo "不存在：$COOKIES_PATH（尚未登录）"
fi

echo "== 日志尾部 =="
tail -5 "$MCP_LOG" 2>/dev/null || true
