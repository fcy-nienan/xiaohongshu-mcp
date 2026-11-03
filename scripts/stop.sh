#!/usr/bin/env bash
# 停止 MCP 服务。
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if ! pid="$(mcp_pid)"; then
  echo "未在运行"
  rm -f "$PID_FILE"
  exit 0
fi

echo "停止 pid=$pid"
kill "$pid" 2>/dev/null || true
for _ in $(seq 1 15); do
  kill -0 "$pid" 2>/dev/null || break
  sleep 1
done
kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
rm -f "$PID_FILE"
echo "已停止"
