#!/usr/bin/env bash
# 无窗口登录：生成二维码 PNG 并用图片查看器打开，手机扫码。
# 有图形界面时优先用 ./scripts/login.sh（窗口里的二维码会自动刷新）。
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if ! mcp_pid >/dev/null; then
  echo "服务未启动，先执行 ./scripts/start.sh"
  exit 1
fi

PY="$ROOT/.venv/bin/python"
[[ -x "$PY" ]] || PY="$(command -v python3)"

cd "$ROOT"
"$PY" scripts/qr.py "$ROOT/data"

QR="$ROOT/data/login-qr-big.png"
[[ -f "$QR" ]] || QR="$ROOT/data/login-qr.png"

if ! xhs_open_path "$QR" >/dev/null 2>&1; then
  echo "二维码已生成：$QR（未能自动打开，请手动查看）"
fi

echo "扫码后用 ./scripts/status.sh 或 check_login_status 确认；登录成功后建议重启服务：./scripts/stop.sh && ./scripts/start.sh"
