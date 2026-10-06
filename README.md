# ASUS VG27AQML1A 输入源自动切换

本项目在 Windows 上监听键鼠切换器产生的 USB 插拔事件，并通过显示器 DDC/CI 切换输入源。项目内已附带 USBLogView 和 ControlMyMonitor；首次填写本机参数后，日常只需运行 `start.cmd`。

## 获取项目

在 Windows 上打开 PowerShell 或命令提示符，克隆本仓库并进入项目目录：

```text
git clone https://github.com/qiaozhi-4/monitor-kvm-switch.git
cd monitor-kvm-switch
```

## 首次配置

确认显示器菜单中的 **DDC/CI** 已开启，并保持 Windows 与 Mac 分别连接到预期的 DisplayPort 和 HDMI 输入。

1. 打开 `tools\ControlMyMonitor\ControlMyMonitor.exe`，选择要控制的显示器，按 **Ctrl+M** 复制显示器信息。将 `Monitor Device Name` 填入 `switch-config.psd1` 的 `MonitorIdentifier`。在工具中确认 **Input Select** 的 VCP Code 为 `60`，再将 DisplayPort 和 HDMI 对应的 Value 填入 `DisplayPortInputValue` 与 `HdmiInputValue`。
2. 打开 `tools\USBLogView\USBLogView.exe`，分别把键鼠切换到两台电脑，观察产生 Plug/Unplug 事件的设备。将目标设备的 **Serial Number** 填入 `TargetSerialNumber`；选能唯一对应目标设备的序列号，不要选 Hub、鼠标或 HID 子设备。
3. 保存 `switch-config.psd1`。配置文件带有字段注释；正常使用不需要编辑 `usb_event_switch.ps1`，也不需要手动输入 PowerShell 命令。

示例配置沿用当前设备参数：序列号 `117F313B3633`、显示器标识 `\\.\DISPLAY1\Monitor0`、DisplayPort 值 `15`、HDMI 值 `17`。首次使用时请用本机读取到的值替换示例值。

## 日常运行

双击项目根目录中的 `start.cmd`，输入菜单选项后按回车确认。选择“现在启动监听”后，启动器会自动关闭；USBLogView 和监听控制图标会留在通知区域。USBLogView 启动时隐藏主窗口并保留自己的托盘图标；右键监听控制图标并选择“停止监听并关闭两个程序”，可同时停止事件监听和 USBLogView。图标是否显示在任务栏箭头的溢出栏中，由 Windows 的通知区域设置决定。`.ps1` 由启动器调用，无需手动运行或输入 PowerShell 命令。

菜单中的“启用当前用户登录自启动”会在当前 Windows 账户登录时自动启动本项目；“禁用当前用户登录自启动”会移除该启动项。禁用后已运行的监听仍会继续，可通过通知区域的监听控制图标停止。登录自启动会直接启动监听，不会显示菜单。

USBLogView 的 `USBLogView.cfg` 已启用插拔事件日志，并将文件名设为 `usb-events.log`。启动器以 USBLogView 所在目录作为工作目录，因此日志实际位于 `tools\USBLogView\usb-events.log`，移动整个项目目录后仍可使用。

目标序列号匹配后，`Plug` 事件切到 DisplayPort，`Unplug` 事件切到 HDMI。其他设备的事件会被忽略。

## 可选：手动切换

如需手动切换显示器，可在项目根目录打开命令提示符并运行下面的示例命令。请将显示器标识和两个输入值替换为 `switch-config.psd1` 中的配置：

```text
"tools\ControlMyMonitor\ControlMyMonitor.exe" /SwitchValue "\\.\DISPLAY1\Monitor0" 60 15 17
```

## 工具与兼容性

工具版本、官方来源和 SHA-256 校验值见 [`tools/README.md`](tools/README.md)。USBLogView 官方说明列出的系统支持范围到 Windows 10；ControlMyMonitor 支持 Windows 11。Windows 11 上的 USBLogView 兼容性需要在目标电脑上确认。

如果没有发生切换，请先确认 DDC/CI 已开启、VCP Code 与输入值正确，并检查 `usb-events.log` 中是否出现配置的序列号和 Plug/Unplug 事件。
