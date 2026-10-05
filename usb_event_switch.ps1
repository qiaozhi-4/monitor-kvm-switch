param(
    # USBLogView 写入事件的日志文件；未传入时读取脚本目录中的 usb-events.log。
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = (Join-Path $PSScriptRoot 'usb-events.log')
)

$LogPath = [System.IO.Path]::GetFullPath($LogPath)

# 从 USBLogView 事件记录中确认目标设备的序列号，只响应该设备的插拔事件。
$targetSerialNumber = '117F313B3633'
# 从 ControlMyMonitor 的 Ctrl+M 复制目标屏幕的 Monitor Device Name。
$monitorIdentifier = '\\.\DISPLAY1\Monitor0'
# 脚本从自身目录调用 ControlMyMonitor.exe，请将它与本脚本放在一起。
$controlMyMonitor = Join-Path $PSScriptRoot 'ControlMyMonitor.exe'
# 输入源值来自 ControlMyMonitor 中 Input Select（VCP Code 60）的 Value。
# Plug 事件切到 Windows 使用的 DisplayPort 输入。
$displayPortInputValue = 15
# Unplug 事件切到 Mac 使用的 HDMI 输入；值变化时改这里，例如改为 18。
$hdmiInputValue = 17

if (-not (Test-Path -LiteralPath $controlMyMonitor -PathType Leaf)) {
    Write-Error "ControlMyMonitor.exe was not found: $controlMyMonitor"
    exit 2
}

$logDirectory = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
    Write-Error "Log directory was not found: $logDirectory"
    exit 2
}

# 在 USBLogView 启动前创建日志文件，确保后续新增的第一条事件也能被监听到。
if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
    New-Item -ItemType File -Path $LogPath | Out-Null
}

# 从日志末尾开始持续读取，避免启动时重放旧事件导致误切换。
Get-Content -LiteralPath $LogPath -Tail 0 -Wait | ForEach-Object {
    $line = $_
    # 一次键鼠切换也会产生 Hub 和 HID 子设备事件，因此只匹配指定序列号及插拔动作。
    if ($line.IndexOf($targetSerialNumber, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $line -match '(?i)\b(Unplug|Plug)\b') {
        $action = $Matches[1]
        $inputValue = if ($action -ieq 'Plug') { $displayPortInputValue } else { $hdmiInputValue }

        # VCP Code 60 表示显示器输入源选择。
        & $controlMyMonitor /SetValue $monitorIdentifier 60 $inputValue
        $exitCode = $LASTEXITCODE
        if (-not [string]::IsNullOrWhiteSpace([string]$exitCode) -and [int]$exitCode -ne 0) {
            Write-Warning "ControlMyMonitor failed with exit code $exitCode for USB $action event."
        }
    }
}
