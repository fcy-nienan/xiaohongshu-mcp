#!/usr/bin/env bash
# 环境自检：一条命令告诉你「这台机器还缺什么」。
# 支持 Linux / WSL2 / macOS（Windows 原生不在支持范围）。
# 用法：./scripts/doctor.sh
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

PASS=0
WARN=0
FAIL=0

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_BAD=$'\033[31m'; C_OFF=$'\033[0m'
else
  C_OK=''; C_WARN=''; C_BAD=''; C_OFF=''
fi

ok()   { printf '  %s✅%s %s\n' "$C_OK" "$C_OFF" "$*"; PASS=$((PASS + 1)); }
warn() { printf '  %s⚠️%s  %s\n' "$C_WARN" "$C_OFF" "$*"; WARN=$((WARN + 1)); }
bad()  { printf '  %s❌%s %s\n' "$C_BAD" "$C_OFF" "$*"; FAIL=$((FAIL + 1)); }
title() { printf '\n%s\n' "$*"; }

plat="$(xhs_platform)"
arch="$(xhs_arch)"

title "== 平台 =="
ok "系统：$plat，架构：$arch"

if xhs_builtin_browser_supported; then
  ok "内置浏览器有对应版本"
else
  case "$plat" in
    darwin)
      bad "Intel Mac（$arch）没有内置浏览器版本，MCP 服务无法启动"
      echo "     替代：用 skill 链路（系统 Chrome）发布，或在 Apple Silicon 机器上跑 MCP"
      ;;
    *)
      bad "当前架构 $arch 没有内置浏览器版本（仅支持 x86_64/amd64）"
      ;;
  esac
fi

title "== Go =="
if command -v go >/dev/null 2>&1; then
  gover="$(go version | awk '{print $3}' | sed 's/^go//')"
  major="${gover%%.*}"
  rest="${gover#*.}"
  minor="${rest%%.*}"
  if [[ "$major" -gt 1 ]] || { [[ "$major" -eq 1 ]] && [[ "$minor" -ge 24 ]]; }; then
    ok "Go $gover"
  else
    bad "Go $gover 偏低，需要 1.24+（go.mod 要求）"
  fi
else
  bad "未安装 Go，无法编译（macOS: brew install go）"
fi

title "== Python 与依赖 =="
PY="$ROOT/.venv/bin/python"
if [[ -x "$PY" ]]; then
  ok "虚拟环境：$PY"
else
  warn "没有 .venv，先跑 ./scripts/bootstrap.sh"
  PY="$(command -v python3 || true)"
  [[ -n "$PY" ]] && ok "系统 python3：$PY" || bad "未安装 python3"
fi

if [[ -n "${PY:-}" ]]; then
  missing=""
  for mod in requests websockets PIL qrcode zxingcpp; do
    "$PY" -c "import $mod" >/dev/null 2>&1 || missing="$missing $mod"
  done
  if [[ -z "$missing" ]]; then
    ok "python 依赖齐全"
  else
    warn "缺少依赖：$missing（跑 ./scripts/bootstrap.sh）"
  fi
fi

title "== 中文字体（生成封面用） =="
font_found=""
for f in \
  "/mnt/c/Windows/Fonts/msyh.ttc" \
  "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc" \
  "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc" \
  "/System/Library/Fonts/PingFang.ttc" \
  "/Library/Fonts/Arial Unicode.ttf"; do
  [[ -f "$f" ]] && { font_found="$f"; break; }
done
if [[ -n "$font_found" ]]; then
  ok "字体：$font_found"
else
  warn "没找到中文字体，gen_covers.py 会报错（Debian/Ubuntu: apt install fonts-noto-cjk）"
fi

title "== 编译产物 =="
if [[ -x "$BIN/xiaohongshu-mcp" ]]; then
  ok "已编译：$BIN/xiaohongshu-mcp"
else
  warn "未编译，跑 ./scripts/build.sh"
fi

title "== 内置浏览器 =="
browser_root="$HOME/.cache/xiaohongshu-mcp/browser"
if [[ -d "$browser_root" ]] && find "$browser_root" -maxdepth 3 -type f \( -name chrome -o -name Chromium \) | grep -q .; then
  ok "已下载"
else
  warn "尚未下载（首次 start 时约 140–190MB）"
fi

if [[ "$plat" == "darwin" ]]; then
  if command -v hdiutil >/dev/null 2>&1; then
    ok "hdiutil 可用（解压 dmg 需要）"
  else
    bad "缺少 hdiutil，无法解压内置浏览器 dmg"
  fi
  warn "若首次启动被 Gatekeeper 拦截：xattr -dr com.apple.quarantine \"$browser_root\""
fi

title "== 服务与端口 =="
if mcp_ready >/dev/null 2>&1; then
  ok "MCP 已在 http://127.0.0.1:$PORT 响应"
elif [[ -n "$(mcp_pid 2>/dev/null || true)" ]]; then
  warn "进程在跑但未响应，看日志：tail -f $MCP_LOG"
else
  warn "服务未启动，跑 ./scripts/start.sh"
fi

if [[ -f "$COOKIES_PATH" ]]; then
  ok "cookies 存在：$COOKIES_PATH"
else
  warn "还没有登录态，跑 ./scripts/login.sh 或 ./scripts/qr.sh"
fi

title "== 网络 =="
code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 https://github.com 2>/dev/null || echo 000)"
if [[ "$code" == "200" ]]; then
  ok "外网可达（github.com 200）"
else
  warn "访问 github.com 返回 $code，检查代理（WSL 常见：需在 start.sh 前 export 代理变量）"
fi

printf '\n== 汇总 ==\n  通过 %d / 警告 %d / 失败 %d\n' "$PASS" "$WARN" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  echo "  有硬性项未通过，先处理 ❌ 再启动服务。"
  exit 1
fi
echo "  可以启动：./scripts/start.sh"
