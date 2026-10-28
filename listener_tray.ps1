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
$switchConfig = Join-Path $projectDirectory 'switch-config.psd1'
$listenerScript = Join-Path $projectDirectory 'usb_event_switch.ps1'
$powershell = Join-Path $PSHOME 'powershell.exe'

$script:listenerProcess = $null
$script:usbLogViewProcess = $null
$script:trayIcon = $null
$script:trayMenu = $null
$script:pollTimer = $null
$script:trayContext = $null
$script:usbLogViewWindowHandle = [IntPtr]::Zero
$script:currentLogDate = $null

function Get-RotatedLogPath {
    param(
        [string]$BaseLogPath,
        [int]$Index
    )

    $logDirectory = [System.IO.Path]::GetDirectoryName($BaseLogPath)
    $logBaseName = [System.IO.Path]::GetFileNameWithoutExtension($BaseLogPath)
    $logExtension = [System.IO.Path]::GetExtension($BaseLogPath)
    return Join-Path $logDirectory "$logBaseName.$Index$logExtension"
}

function Remove-ExpiredDailyLogs {
    param(
        [string]$BaseLogPath,
        [datetime]$Date
    )

    $oldestDate = $Date.Date.AddDays(-6)

    for ($index = 1; $index -le 6; $index++) {
        $archivePath = Get-RotatedLogPath -BaseLogPath $BaseLogPath -Index $index
        if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
            $archiveDate = (Get-Item -LiteralPath $archivePath).LastWriteTime.Date
            if ($archiveDate -lt $oldestDate) {
                Remove-Item -LiteralPath $archivePath -Force
            }
        }
    }
}

function Initialize-DailyLog {
    param(
        [string]$BaseLogPath,
        [datetime]$Date,
        [switch]$ForceRotation
    )

    $oldestDate = $Date.Date.AddDays(-6)
    if (Test-Path -LiteralPath $BaseLogPath -PathType Leaf) {
        $activeLogDate = (Get-Item -LiteralPath $BaseLogPath).LastWriteTime.Date
        if ($ForceRotation -or $activeLogDate -lt $Date.Date) {
            $oldestArchivePath = Get-RotatedLogPath -BaseLogPath $BaseLogPath -Index 6
            if (Test-Path -LiteralPath $oldestArchivePath -PathType Leaf) {
                Remove-Item -LiteralPath $oldestArchivePath -Force
            }

            for ($index = 5; $index -ge 1; $index--) {
                $archivePath = Get-RotatedLogPath -BaseLogPath $BaseLogPath -Index $index
                if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
                    $nextArchivePath = Get-RotatedLogPath -BaseLogPath $BaseLogPath -Index ($index + 1)
                    Move-Item -LiteralPath $archivePath -Destination $nextArchivePath -Force
                }
            }

            if ($activeLogDate -ge $oldestDate) {
                $firstArchivePath = Get-RotatedLogPath -BaseLogPath $BaseLogPath -Index 1
                Move-Item -LiteralPath $BaseLogPath -Destination $firstArchivePath -Force
            }
            else {
                Remove-Item -LiteralPath $BaseLogPath -Force
            }
        }
    }

    if (-not (Test-Path -LiteralPath $BaseLogPath -PathType Leaf)) {
        New-Item -ItemType File -Path $BaseLogPath | Out-Null
    }

    Remove-ExpiredDailyLogs -BaseLogPath $BaseLogPath -Date $Date
}

function Stop-MonitoringProcesses {
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

    $script:listenerProcess = $null
    $script:usbLogViewProcess = $null
    $script:usbLogViewWindowHandle = [IntPtr]::Zero
}

function Start-MonitoringForDate {
    param(
        [datetime]$Date,
        [switch]$ReconcileTargetDevice
    )

    $listenerArguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $listenerScript
    if ($ReconcileTargetDevice) {
        $script:usbLogViewProcess = Start-Process -FilePath $usbLogView `
            -WorkingDirectory $usbLogViewDirectory `
            -WindowStyle Minimized `
            -PassThru
        $listenerArguments += ' -ReconcileTargetDevice'
    }

    $script:listenerProcess = Start-Process -FilePath $powershell `
        -ArgumentList $listenerArguments `
        -WorkingDirectory $projectDirectory `
        -WindowStyle Hidden `
        -PassThru

    if (-not $ReconcileTargetDevice) {
        $script:usbLogViewProcess = Start-Process -FilePath $usbLogView `
            -WorkingDirectory $usbLogViewDirectory `
            -WindowStyle Minimized `
            -PassThru
    }

    $script:currentLogDate = $Date.Date
}

try {
    $switchConfiguration = Import-PowerShellDataFile -LiteralPath $switchConfig -ErrorAction Stop
    $logPathValue = ([string]$switchConfiguration.LogPath).Trim()
    if ([string]::IsNullOrWhiteSpace($logPathValue) -or [System.IO.Path]::IsPathRooted($logPathValue)) {
        throw 'switch-config.psd1 中的 LogPath 必须是相对于项目目录的路径。'
    }

    $baseLogPath = [System.IO.Path]::GetFullPath((Join-Path $projectDirectory $logPathValue))
    $logDirectory = [System.IO.Path]::GetDirectoryName($baseLogPath)
    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        throw "未找到日志目录：$logDirectory"
    }

    $today = (Get-Date).Date
    Initialize-DailyLog -BaseLogPath $baseLogPath -Date $today
    Start-MonitoringForDate -Date $today

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
        $today = (Get-Date).Date
        if ($today -ne $script:currentLogDate) {
            Stop-MonitoringProcesses
            try {
                Initialize-DailyLog -BaseLogPath $baseLogPath -Date $today -ForceRotation
                Start-MonitoringForDate -Date $today -ReconcileTargetDevice
            }
            catch {
                Write-Warning "切换每日 USB 日志失败：$($_.Exception.Message)"
                $script:trayContext.ExitThread()
            }
            return
        }

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

    Stop-MonitoringProcesses
}
