#!/usr/bin/env bash
# 有窗口扫码登录（窗口经 WSLg 显示到 Windows 桌面）。
# 无窗口场景请改用 MCP 的 get_login_qrcode 工具。
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

[[ -x "$BIN/xiaohongshu-login" ]] || { echo "未找到 $BIN/xiaohongshu-login，请先运行 ./scripts/build.sh"; exit 1; }
[[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]] || { echo "没有图形环境（DISPLAY/WAYLAND_DISPLAY 均为空）"; exit 1; }

cd "$REPO"
echo "cookies: $COOKIES_PATH"
exec "$BIN/xiaohongshu-login"
