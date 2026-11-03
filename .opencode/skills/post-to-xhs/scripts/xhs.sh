#!/usr/bin/env bash
# post-to-xhs 脚本入口（WSL/Linux 适配版）。
# 用法： scripts/xhs.sh cdp_publish.py login
#       scripts/xhs.sh publish_pipeline.py --headless --title-file ... --content-file ...
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# 仓库根 = skill 目录向上 3 级（<root>/.opencode/skills/post-to-xhs）
ROOT="${XHS_SKILL_ROOT:-$(cd "$SKILL_DIR/../../.." && pwd)}"

# 优先用项目 venv；没有就退回系统 python3
if [[ -x "$ROOT/.venv/bin/python" ]]; then
  PY="$ROOT/.venv/bin/python"
else
  PY="$(command -v python3)"
fi

script="${1:?用法: xhs.sh <script.py> [args...]}"
shift

exec "$PY" "$SKILL_DIR/scripts/$script" "$@"
