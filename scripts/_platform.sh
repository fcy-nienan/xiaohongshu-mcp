#!/usr/bin/env bash
# 平台探测与跨平台小工具。只覆盖 Linux / WSL / macOS（Windows 原生不在支持范围）。
# 用法：source "$(dirname "$0")/_platform.sh"

# 归一化平台：linux / wsl / darwin
xhs_platform() {
  local kernel
  kernel="$(uname -s)"
  if [[ "$kernel" == "Darwin" ]]; then
    echo "darwin"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}

xhs_arch() {
  uname -m
}

# 是否有图形环境：macOS 视为原生可用；Linux/WSL 需要 DISPLAY 或 WAYLAND_DISPLAY
xhs_has_display() {
  case "$(xhs_platform)" in
    darwin) return 0 ;;
    *) [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]] ;;
  esac
}

# 用系统默认程序打开文件/目录
xhs_open_path() {
  local path="$1"
  case "$(xhs_platform)" in
    darwin)
      open "$path"
      ;;
    wsl)
      explorer.exe "$(wslpath -w "$path")"
      ;;
    *)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$path"
      else
        echo "没有可用的打开方式，请手动打开：$path" >&2
        return 1
      fi
      ;;
  esac
}

# 内置浏览器支持矩阵，返回 0 表示支持，1 表示不支持
xhs_builtin_browser_supported() {
  local plat arch
  plat="$(xhs_platform)"
  arch="$(xhs_arch)"
  case "$plat" in
    darwin) [[ "$arch" == "arm64" ]] ;;
    wsl|linux) [[ "$arch" == "x86_64" || "$arch" == "amd64" ]] ;;
    *) return 1 ;;
  esac
}
