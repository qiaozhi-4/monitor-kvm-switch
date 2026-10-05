@{
    # 日常只需运行 start.cmd；修改本文件即可，不必手动运行或编辑 PS1 脚本。
    # USBLogView 中目标设备在 Plug/Unplug 事件里的唯一 Serial Number。
    TargetSerialNumber = '117F313B3633'

    # 在 ControlMyMonitor 选中目标屏幕后按 Ctrl+M，填写 Monitor Device Name。
    MonitorIdentifier = '\\.\DISPLAY1\Monitor0'

    # 显示器输入选择功能的 VCP Code；当前显示器使用 60。
    VcpCode = 60

    # 在 ControlMyMonitor 中读取 VCP Code 60 的 Value，按实际接线填写。
    # Plug 事件切到 Windows 使用的 DisplayPort。
    DisplayPortInputValue = 15
    # Unplug 事件切到另一台电脑使用的 HDMI。
    HdmiInputValue = 17

    # USBLogView.cfg 也将事件写到这个文件。路径相对于项目目录。
    LogPath = 'tools\USBLogView\usb-events.log'
}
