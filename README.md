# VG27AQML1A 输入源切换脚本

这个仓库包含两台电脑切换同一台 ASUS VG27AQML1A 显示器输入源的脚本：

| 在哪台电脑运行 | 脚本 | 切换结果 |
| --- | --- | --- |
| macOS | `./switch_to_win.sh` | 切到 DisplayPort / Windows，输入值 `15` |
| Windows | `switch_to_mac.bat` | 切到 HDMI / Mac，输入值 `17` |

脚本使用显示器的 DDC/CI 输入选择 VCP `0x60`。Windows 上的 `17` 已由 ControlMyMonitor 验证可切回 Mac；Mac 脚本按 BetterDisplay 官方 CLI 格式发送 VCP `0x60`、值 `15`，实际切换仍待本机 CLI 通信恢复后验证。

## macOS 准备

1. 安装并运行 `/Applications/BetterDisplay.app`。
2. 安装 BetterDisplay 官方 CLI `betterdisplaycli`。本机安装路径为 `/opt/homebrew/bin/betterdisplaycli`。
3. 确认 BetterDisplay 的 `Settings > Application > Integration` 中 CLI / 通知集成没有被关闭（官方文档说明默认开启）。
4. 在仓库目录执行：

   ```sh
   ./switch_to_win.sh
   ```

如果脚本报告 BetterDisplay 没有响应，脚本会保留 CLI 的错误码和诊断信息。本机目前在 BetterDisplay 已启动、集成偏好已开启时，CLI 仍会超时，因此 Mac 到 Windows 的实际切换尚未确认。

## Windows 准备

将 `ControlMyMonitor.exe` 放在 `switch_to_mac.bat` 同一目录，或把它所在目录加入 `PATH`。双击 `switch_to_mac.bat` 即可切到 Mac。

脚本默认按显示器名 `VG27AQML1A` 定位。如果 ControlMyMonitor 中显示的名称不同，或同型号显示器不止一台，请编辑 `MONITOR_ID`，填入 ControlMyMonitor 的 Monitor Device Name、序列号或其他唯一标识。可在 ControlMyMonitor 中选中显示器并按 `Ctrl+M` 查看这些标识。

## 当前安装记录

- BetterDisplay 4.3.7 已安装到 `/Applications/BetterDisplay.app`，并能识别 VG27AQML1A。
- BetterDisplay 官方 `betterdisplaycli` 1.0.1 已安装到 `/opt/homebrew/bin/betterdisplaycli`。
- 本机 macOS 为 26.2；检查过官方 BetterDisplay 5.0.5 安装包，其最低系统版本为 26.3，因此保留兼容的 4.3.7。
- 已在 BetterDisplay 设置界面确认 CLI / 通知集成开关为开启。只读读取 VCP `0x60` 时，`betterdisplaycli` 仍等待通知响应并超时，因此暂不能确认脚本是否能实际切换显示器输入源。

## 仓库

本目录已初始化为 Git 仓库，主分支为 `main`。
