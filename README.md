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

自动切换脚本的设备参数定义在 `usb_event_switch.ps1` 开头附近。更换键鼠切换器、显示器或输入源后，按下表找到对应值并修改脚本：

| 脚本参数 | 取值方法 |
| --- | --- |
| `$LogPath` | 运行脚本时用 `-LogPath` 指定；值必须与 USBLogView **F9 > Advanced Options** 中设置的日志文件路径相同。省略参数时，默认读取脚本目录下的 `usb-events.log`。 |
| `$targetSerialNumber` | 在 USBLogView 的设备事件中找到切换键鼠时会产生 Plug/Unplug 记录的设备，读取其 **Serial Number**。分别切换两台电脑，确认该序列号属于目标设备而非 Hub、鼠标或 HID 子设备。 |
| `$monitorIdentifier` | 在 ControlMyMonitor 中选中要控制的屏幕，按 **Ctrl+M**，复制 **Monitor Device Name**。多屏时应为目标屏幕选择唯一标识。 |
| `$displayPortInputValue`、`$hdmiInputValue` | 在 ControlMyMonitor 中查看目标屏幕 **Input Select**（VCP Code `60`）对应的 **Value**。按实际连接关系分别填写 DP 和 HDMI 的值；例如 Mac 的 HDMI 值变为 `18` 时，将 `$hdmiInputValue` 改为 `18`。 |
| VCP Code `60` | 在 ControlMyMonitor 列表中确认 **Input Select** 对应的 VCP Code；脚本用它指定要修改的显示器功能。 |
| `$controlMyMonitor` | 脚本会自动从自身目录查找 `ControlMyMonitor.exe`，无需改变量；确保 exe 与脚本放在同一目录。 |

## 3. 创建一个切换快捷方式

创建 `ControlMyMonitor.exe` 的快捷方式并放到桌面。右键快捷方式，打开 **属性 > 快捷方式**，将 **目标** 设置为：

```text
"E:\nirsoft\controlmymonitor\ControlMyMonitor.exe" /SwitchValue "\\.\DISPLAY1\Monitor0" 60 15 17
```

可在命令提示符中直接运行同一命令；可执行文件路径只写一次，后面紧跟 `/SwitchValue` 参数。
如果输入源值变化，这个手动快捷方式也要同步修改目标末尾的两个输入值；例如 Mac 的 HDMI 值从 `17` 改为 `18`，将末尾的 `15 17` 改为 `15 18`。

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

5. 保持 USBLogView 和 PowerShell 监听脚本运行，切换键鼠到 Mac 再切回 Windows，确认显示器依次切到 `$hdmiInputValue` 和 `$displayPortInputValue` 当前配置的输入。要让它们每次登录后自动运行，可按 `Win+R`，输入 `shell:startup`，把 `E:\nirsoft\usblogview\USBLogView.exe` 的快捷方式以及监听脚本的快捷方式放进打开的启动文件夹。监听脚本快捷方式的目标可设为：

   ```text
   powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "E:\nirsoft\controlmymonitor\usb_event_switch.ps1" -LogPath "E:\nirsoft\usblogview\usb-events.log"
   ```

脚本按日志行中的事件类型和序列号切换输入源：`Plug` 使用 `$displayPortInputValue` 切到 DisplayPort，`Unplug` 使用 `$hdmiInputValue` 切到 HDMI。当前默认值分别为 `15` 和 `17`；输入源值或设备变化时，按上表获取并修改脚本开头的配置。脚本会从自身所在目录调用 `ControlMyMonitor.exe`，目标显示器标识由 `$monitorIdentifier` 指定。
