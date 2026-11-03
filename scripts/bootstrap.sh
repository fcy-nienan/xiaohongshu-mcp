#!/usr/bin/env bash
# 一次性初始化：准备 python 依赖（.venv）。
# 新机器上克隆仓库后先跑这个，再 build/start。
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

cd "$ROOT"

if [[ -x "$ROOT/.venv/bin/python" ]]; then
  PY="$ROOT/.venv/bin/python"
  echo "复用已有 .venv"
else
  echo "创建 .venv ..."
  if command -v uv >/dev/null 2>&1; then
    uv venv "$ROOT/.venv"
  else
    python3 -m venv "$ROOT/.venv"
  fi
  PY="$ROOT/.venv/bin/python"
fi

if command -v uv >/dev/null 2>&1; then
  uv pip install --python "$PY" -r "$ROOT/requirements.txt"
else
  "$PY" -m pip install -U pip
  "$PY" -m pip install -r "$ROOT/requirements.txt"
fi

echo "依赖就绪：$PY"
echo "下一步：./scripts/build.sh && ./scripts/start.sh"
