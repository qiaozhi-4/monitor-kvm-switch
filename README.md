# ASUS VG27AQML1A 输入源切换

在 Windows 上可以用 `Ctrl+Alt+M` 手动切换，也可以让键鼠切换器的 USB 接入/断开事件自动切换显示器输入源：DisplayPort 接 Windows，HDMI 接 Mac。

## 1. 下载并解压 ControlMyMonitor

1. 打开 [ControlMyMonitor 官方下载页](https://www.nirsoft.net/utils/control_my_monitor.html)。
2. 点击页面底部的 **Download ControlMyMonitor**，下载 ZIP 压缩包并解压到固定目录，例如 `C:\Tools\ControlMyMonitor`。
3. 确认显示器菜单中的 **DDC/CI** 已开启，然后运行解压目录里的 `ControlMyMonitor.exe`。这是免安装工具，后续快捷方式会直接调用这个程序。

## 2. 确认显示器和输入值

在 ControlMyMonitor 窗口中，从下方的显示器列表选择 ASUS VG27AQML1A，并确认列表里有 **Input Select**（VCP Code `60`）。本机的输入值对应关系是：

| VCP Code `60` 的值 | 输入源 | 连接的电脑 |
| --- | --- | --- |
| `15` | DisplayPort | Windows |
| `17` | HDMI | Mac |

如果列表中的显示器名称不是 `VG27AQML1A`，按 `Ctrl+M` 复制显示器标识，并在下方快捷方式目标中替换为唯一的显示器名称、序列号或 Short Monitor ID。多台显示器时应使用唯一标识。

## 3. 创建一个切换快捷方式

在解压目录中右键 `ControlMyMonitor.exe`，选择 **创建快捷方式**，再把快捷方式复制到桌面。右键桌面快捷方式，打开 **属性 > 快捷方式**，在 **目标** 中现有程序路径的结束引号后添加：

```text
/SwitchValue "VG27AQML1A" 60 15 17
```

例如，假设程序放在 `C:\Tools\ControlMyMonitor`，**目标** 应为：

```text
"C:\Tools\ControlMyMonitor\ControlMyMonitor.exe" /SwitchValue "VG27AQML1A" 60 15 17
```

如果程序在其他目录，请保留快捷方式中原有的程序路径，只在结束引号后添加参数。若显示器标识不同，也在这里替换 `VG27AQML1A`。

仍在 **属性 > 快捷方式** 页面，点击 **快捷键** 输入框，按下 `Ctrl+Alt+M`，然后点击 **应用**。

之后先把键盘切到 Windows，按一次快捷键即可切换到另一台电脑对应的显示器输入：当前是 `15`（DisplayPort / Windows）时会切到 `17`（HDMI / Mac）；当前是 `17` 时会切回 `15`。

如果按快捷键没有切换，先确认显示器已开启 DDC/CI、快捷方式目标中的程序路径和显示器标识正确，并在 ControlMyMonitor 中确认该屏幕显示 VCP Code `60`。

## 4. 根据键鼠 USB 连接自动切换

这台键鼠切换器在 Windows 上会产生 USB 断开和重新接入事件。日志中的 Logitech G610 设备序列号是 `117F313B3633`；`usb_event_switch.ps1` 只响应这个序列号，忽略同一次切换产生的 Hub、鼠标和 HID 子设备事件。

1. 从 [USBDeview 官方页面](https://www.nirsoft.net/utils/usb_devices_view.html) 下载并运行 USBDeview。
2. 将仓库中的 `usb_event_switch.ps1` 复制到 `C:\Tools\ControlMyMonitor`，与 `ControlMyMonitor.exe` 放在同一目录。
3. 在 USBDeview 打开 **Options > Advanced Options**，分别启用插入设备和拔出设备时执行命令。
4. 插入事件命令填入：

   ```text
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\ControlMyMonitor\usb_event_switch.ps1" -Action Plug -SerialNumber "%serial_number%"
   ```

5. 拔出事件命令填入：

   ```text
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\ControlMyMonitor\usb_event_switch.ps1" -Action Unplug -SerialNumber "%serial_number%"
   ```

6. 先保持 USBDeview 运行，切换键鼠到 Mac 再切回 Windows，确认显示器依次切到 `17` 和 `15`。要让监听器每次登录后自动运行，可按 `Win+R`，输入 `shell:startup`，再把 USBDeview 的快捷方式放进打开的启动文件夹。

PowerShell 脚本会按序列号过滤事件，因此不会因其他 USB 设备或同次切换中的多个 HID 事件而重复切屏。如果 ControlMyMonitor 或显示器标识不同，请相应修改 `usb_event_switch.ps1` 中的路径或常量。USBDeview 可以调用设备接入/断开命令并替换 `%serial_number%` 等设备变量，ControlMyMonitor 通过 `/SetValue` 设置输入源。
