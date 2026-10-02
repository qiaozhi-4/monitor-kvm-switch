# ASUS VG27AQML1A 输入源切换

在 Windows 上用 ControlMyMonitor 的两个快捷方式切换显示器输入源：DisplayPort 接 Windows，HDMI 接 Mac。切到 Windows 后，按对应的 Windows 快捷键即可切换显示器输入。

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

如果列表中的显示器名称不是 `VG27AQML1A`，按 `Ctrl+M` 复制显示器标识，并在下方快捷方式命令中用唯一的显示器名称、序列号或 Short Monitor ID 替换它。多台显示器时应使用唯一标识。

## 3. 创建两个快捷方式

在解压目录中右键 `ControlMyMonitor.exe`，选择 **创建快捷方式**，将快捷方式复制到桌面并复制一份。分别重命名为“切换到 Windows”和“切换到 Mac”。

逐个右键快捷方式，打开 **属性 > 快捷方式**，在 **目标** 的程序路径后添加对应参数。假设程序放在 `C:\Tools\ControlMyMonitor`，目标应为：

| 快捷方式 | 目标 | 用途 |
| --- | --- | --- |
| 切换到 Windows | `"C:\Tools\ControlMyMonitor\ControlMyMonitor.exe" /SetValue "VG27AQML1A" 60 15` | 切到 DisplayPort |
| 切换到 Mac | `"C:\Tools\ControlMyMonitor\ControlMyMonitor.exe" /SetValue "VG27AQML1A" 60 17` | 切到 HDMI |

如果 ControlMyMonitor 不在示例目录，先把两行中的程序路径改成实际的 `ControlMyMonitor.exe` 路径。保留路径两侧的引号，并把 `/SetValue ...` 参数放在结束引号之后。

## 4. 设置并使用键盘快捷键

仍在每个快捷方式的 **属性 > 快捷方式** 页面，点击 **快捷键** 输入框，按下想使用的组合键，然后点击 **应用**。例如，可以给“切换到 Windows”设置 `Ctrl+Alt+1`，给“切换到 Mac”设置 `Ctrl+Alt+2`；也可以使用自己习惯且未被其他程序占用的组合键。

之后先把键盘切到 Windows，再按对应组合键：`15` 切到 Windows 的 DisplayPort，`17` 切到 Mac 的 HDMI。第一次设置时可双击两个快捷方式，确认显示器输入源切换正确。

如果按快捷键没有切换，先确认显示器已开启 DDC/CI、快捷方式目标中的程序路径和显示器标识正确，并在 ControlMyMonitor 中确认该屏幕显示 VCP Code `60`。
