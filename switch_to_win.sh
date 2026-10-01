#!/bin/bash
# 遇到未处理的错误、未定义变量或管道失败时立即退出，避免报告假成功。
set -euo pipefail

# 指定 BetterDisplay 应用位置、目标显示器名称和 DP 输入值。
APP="/Applications/BetterDisplay.app"
DISPLAY_NAME="VG27AQML1A"
INPUT_CODE="15" # DisplayPort (VCP inputSelect)

# 应用不存在时无法通过它发送 DDC 命令，输出提示并返回 127。
if [[ ! -d "$APP" ]]; then
  printf 'BetterDisplay is not installed at %s\n' "$APP" >&2
  exit 127
fi

# 先从 PATH 查找 CLI；命令查找失败时用 true 接住错误，继续尝试 Homebrew 常见路径。
CLI="$(command -v betterdisplaycli || true)"
# Apple Silicon 的 Homebrew 默认把 CLI 安装在 /opt/homebrew/bin。
if [[ -z "$CLI" && -x /opt/homebrew/bin/betterdisplaycli ]]; then
  CLI="/opt/homebrew/bin/betterdisplaycli"
fi
# 确认 CLI 路径已找到且文件可执行，否则提示安装要求并退出。
if [[ -z "$CLI" || ! -x "$CLI" ]]; then
  printf 'betterdisplaycli was not found. Install the official BetterDisplay CLI first.\n' >&2
  exit 127
fi

# 通过 BetterDisplay 向目标屏幕发送 DDC/CI：VCP 0x60 是输入选择，15 对应本显示器的 DisplayPort。
if "$CLI" set \
  "--namelike=$DISPLAY_NAME" \
  --feature=ddc \
  --vcp=0x60 \
  "--value=$INPUT_CODE"; then
  # 命令成功时告知用户已经发送的输入选择值。
  printf 'Sent DisplayPort input selection to %s (VCP 0x60=%s).\n' "$DISPLAY_NAME" "$INPUT_CODE"
else
  # 在执行其他命令前保存 CLI 错误码，以便原样返回。
  status=$?
  printf 'BetterDisplay CLI command failed. Check the CLI diagnostic above and verify that the app responds to CLI/notification integration.\n' >&2
  exit "$status"
fi
