# ASUS VG27AQML1A 输入源切换

在 Windows 上可以用 `Ctrl+Alt+M` 手动切换，也可以让键鼠切换器的 USB 接入/断开事件自动切换显示器输入源：DisplayPort 接 Windows，HDMI 接 Mac。

## 1. 工具目录

当前目录配置：

- USBLogView：`E:\nirsoft\usblogview`（程序为 `USBLogView.exe`）
- ControlMyMonitor：`E:\nirsoft\controlmymonitor`（程序为 `ControlMyMonitor.exe`）
- 自动切换脚本：`E:\nirsoft\controlmymonitor\usb_event_switch.ps1`

确认显示器菜单中的 **DDC/CI** 已开启。ControlMyMonitor 是免安装工具。

## 2. 确认显示器和输入值

在 ControlMyMonitor 窗口中选择 ASUS 显示器，并确认列表里有 **Input Select**（VCP Code `60`）。本机的输入值对应关系是：

| VCP Code `60` 的值 | 输入源 | 连接的电脑 |
| --- | --- | --- |
| `15` | DisplayPort | Windows |
| `17` | HDMI | Mac |

显示器标识使用 `\\.\DISPLAY1\Monitor0`。这是从 ControlMyMonitor 的 **Ctrl+M**（Copy Monitor Settings）复制的 Monitor Device Name。像 `VG27AQML1A` 这样的型号名如果无法识别，就使用 Ctrl+M 复制出的标识；有多台显示器时，标识必须唯一。

## 3. 创建一个切换快捷方式

创建 `ControlMyMonitor.exe` 的快捷方式并放到桌面。右键快捷方式，打开 **属性 > 快捷方式**，将 **目标** 设置为：

```text
"E:\nirsoft\controlmymonitor\ControlMyMonitor.exe" /SwitchValue "\\.\DISPLAY1\Monitor0" 60 15 17
```

可在命令提示符中直接运行同一命令；可执行文件路径只写一次，后面紧跟 `/SwitchValue` 参数。

仍在 **属性 > 快捷方式** 页面，点击 **快捷键** 输入框，按下 `Ctrl+Alt+M`，然后点击 **应用**。

之后先把键盘切到 Windows，按一次快捷键即可切换到另一台电脑对应的显示器输入：当前是 `15`（DisplayPort / Windows）时会切到 `17`（HDMI / Mac）；当前是 `17` 时会切回 `15`。

如果按快捷键没有切换，先确认显示器已开启 DDC/CI、快捷方式目标中的程序路径和显示器标识正确，并在 ControlMyMonitor 中确认该屏幕显示 VCP Code `60`。

## 4. 根据键鼠 USB 连接自动切换

这台键鼠切换器在 Windows 上会产生 USB 断开和重新接入事件。USBLogView 将事件写入日志文件；`usb_event_switch.ps1` 读取新增日志，只响应 Logitech G610 的序列号 `117F313B3633`，忽略同一次切换产生的 Hub、鼠标和 HID 子设备事件。

1. 运行 `E:\nirsoft\usblogview\USBLogView.exe`。如尚未下载，可从 [USBLogView 官方页面](https://www.nirsoft.net/utils/usb_log_view.html) 获取。
2. 将仓库中的 `usb_event_switch.ps1` 复制到 `E:\nirsoft\controlmymonitor`，与 `ControlMyMonitor.exe` 放在同一目录。
3. 在 USBLogView 按 `F9` 打开 **Options > Advanced Options**，启用 **Add every plug/unplug event into a log file**，将日志文件设为 `E:\nirsoft\usblogview\usb-events.log`。此处只需配置事件写入日志文件。
4. 启动事件监听脚本：

   ```text
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "E:\nirsoft\controlmymonitor\usb_event_switch.ps1" -LogPath "E:\nirsoft\usblogview\usb-events.log"
   ```

5. 保持 USBLogView 和 PowerShell 监听脚本运行，切换键鼠到 Mac 再切回 Windows，确认显示器依次切到 `17` 和 `15`。要让它们每次登录后自动运行，可按 `Win+R`，输入 `shell:startup`，把 `E:\nirsoft\usblogview\USBLogView.exe` 的快捷方式以及监听脚本的快捷方式放进打开的启动文件夹。监听脚本快捷方式的目标可设为：

   ```text
   powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "E:\nirsoft\controlmymonitor\usb_event_switch.ps1" -LogPath "E:\nirsoft\usblogview\usb-events.log"
   ```

脚本按日志行中的事件类型和序列号切换输入源：`Plug` 对应 DisplayPort（`15`），`Unplug` 对应 HDMI（`17`）。脚本会从自身所在目录调用 `ControlMyMonitor.exe`，目标显示器标识设为 `\\.\DISPLAY1\Monitor0`。
