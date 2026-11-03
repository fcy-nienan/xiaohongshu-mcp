#!/usr/bin/env bash
# 启动 MCP 服务。用法：
#   ./scripts/start.sh            # 无头模式（默认）
#   ./scripts/start.sh --headed   # 有窗口模式，窗口经 WSLg 显示到 Windows 桌面，适合调试
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if pid="$(mcp_pid)"; then
  echo "已经在运行 (pid=$pid)，端口 http://localhost:$PORT/mcp"
  exit 0
fi

[[ -x "$BIN/xiaohongshu-mcp" ]] || { echo "未找到 $BIN/xiaohongshu-mcp，请先运行 ./scripts/build.sh"; exit 1; }

# 只监听回环地址，避免未启用 AUTH_TOKEN 时暴露到局域网
opts=(-port "127.0.0.1:$PORT")
if [[ "${1:-}" == "--headed" ]]; then
  opts+=(-headless=false)
  echo "==> 有窗口模式（WSLg）"
fi

cd "$REPO"
nohup "$BIN/xiaohongshu-mcp" "${opts[@]}" >>"$MCP_LOG" 2>&1 &
echo $! > "$PID_FILE"
echo "启动中 (pid=$(cat "$PID_FILE"))，日志：$MCP_LOG"

for _ in $(seq 1 90); do
  if mcp_ready; then
    echo "就绪：http://localhost:$PORT/mcp"
    exit 0
  fi
  sleep 1
done

echo "90 秒内未就绪，最后 20 行日志："
tail -20 "$MCP_LOG"
exit 1
