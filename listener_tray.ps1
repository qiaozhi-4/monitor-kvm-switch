Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class MonitorKvmWindow {
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr windowHandle);

    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr windowHandle);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr windowHandle, int command);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr windowHandle);
}
'@

$projectDirectory = $PSScriptRoot
$usbLogViewDirectory = Join-Path $projectDirectory 'tools\USBLogView'
$usbLogView = Join-Path $usbLogViewDirectory 'USBLogView.exe'
$listenerScript = Join-Path $projectDirectory 'usb_event_switch.ps1'
$powershell = Join-Path $PSHOME 'powershell.exe'
$listenerArguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $listenerScript

$script:listenerProcess = $null
$script:usbLogViewProcess = $null
$script:trayIcon = $null
$script:trayMenu = $null
$script:pollTimer = $null
$script:trayContext = $null
$script:usbLogViewWindowHandle = [IntPtr]::Zero

try {
    $script:listenerProcess = Start-Process -FilePath $powershell `
        -ArgumentList $listenerArguments `
        -WorkingDirectory $projectDirectory `
        -WindowStyle Hidden `
        -PassThru

    $script:usbLogViewProcess = Start-Process -FilePath $usbLogView `
        -WorkingDirectory $usbLogViewDirectory `
        -PassThru

    $script:trayContext = New-Object System.Windows.Forms.ApplicationContext
    $script:trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $showMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $showMenuItem.Text = '显示 USBLogView'
    [void]$script:trayMenu.Items.Add($showMenuItem)
    $stopMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $stopMenuItem.Text = '停止监听并关闭两个程序'
    [void]$script:trayMenu.Items.Add($stopMenuItem)

    $script:trayIcon = New-Object System.Windows.Forms.NotifyIcon
    $script:trayIcon.Icon = [System.Drawing.SystemIcons]::Application
    $script:trayIcon.Text = 'Monitor KVM Switch'
    $script:trayIcon.ContextMenuStrip = $script:trayMenu
    $script:trayIcon.Visible = $true

    $showMenuItem.Add_Click({
        if ($script:usbLogViewWindowHandle -ne [IntPtr]::Zero -and
            [MonitorKvmWindow]::IsWindow($script:usbLogViewWindowHandle)) {
            [void][MonitorKvmWindow]::ShowWindow($script:usbLogViewWindowHandle, 9)
            [void][MonitorKvmWindow]::SetForegroundWindow($script:usbLogViewWindowHandle)
        }
    })
    $stopMenuItem.Add_Click({ $script:trayContext.ExitThread() })

    $script:pollTimer = New-Object System.Windows.Forms.Timer
    $script:pollTimer.Interval = 250
    $script:pollTimer.Add_Tick({
        $script:listenerProcess.Refresh()
        $script:usbLogViewProcess.Refresh()
        if ($script:listenerProcess.HasExited -or $script:usbLogViewProcess.HasExited) {
            $script:trayContext.ExitThread()
            return
        }

        $windowHandle = $script:usbLogViewProcess.MainWindowHandle
        if ($windowHandle -ne [IntPtr]::Zero) {
            $script:usbLogViewWindowHandle = $windowHandle
            if ([MonitorKvmWindow]::IsIconic($windowHandle)) {
                [void][MonitorKvmWindow]::ShowWindow($windowHandle, 0)
            }
        }
    })
    $script:pollTimer.Start()

    [System.Windows.Forms.Application]::Run($script:trayContext)
}
finally {
    if ($null -ne $script:pollTimer) {
        $script:pollTimer.Stop()
        $script:pollTimer.Dispose()
    }
    if ($null -ne $script:trayIcon) {
        $script:trayIcon.Visible = $false
        $script:trayIcon.Dispose()
    }
    if ($null -ne $script:trayMenu) {
        $script:trayMenu.Dispose()
    }

    foreach ($process in @($script:listenerProcess, $script:usbLogViewProcess)) {
        if ($null -eq $process) {
            continue
        }

        try {
            $process.Refresh()
            if (-not $process.HasExited) {
                $process.Kill()
                [void]$process.WaitForExit(5000)
            }
        }
        catch {
        }
        $process.Dispose()
    }
}
