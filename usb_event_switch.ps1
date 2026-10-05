$configPath = Join-Path $PSScriptRoot 'switch-config.psd1'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Error "未找到配置文件：$configPath"
    exit 2
}

try {
    $configuration = Import-PowerShellDataFile -LiteralPath $configPath -ErrorAction Stop
}
catch {
    Write-Error "无法读取配置文件 '$configPath'：$($_.Exception.Message)"
    exit 2
}

if ($configuration -isnot [System.Collections.Hashtable]) {
    Write-Error "配置文件 '$configPath' 必须包含一个 PowerShell 哈希表。"
    exit 2
}

$requiredSettings = @(
    'TargetSerialNumber',
    'MonitorIdentifier',
    'VcpCode',
    'DisplayPortInputValue',
    'HdmiInputValue',
    'LogPath'
)

foreach ($setting in $requiredSettings) {
    if (-not $configuration.ContainsKey($setting) -or
        [string]::IsNullOrWhiteSpace([string]$configuration[$setting])) {
        Write-Error "配置文件 '$configPath' 缺少设置 '$setting' 或其值为空。"
        exit 2
    }
}

try {
    $vcpCode = [int]$configuration.VcpCode
    $displayPortInputValue = [int]$configuration.DisplayPortInputValue
    $hdmiInputValue = [int]$configuration.HdmiInputValue
}
catch {
    Write-Error "配置文件 '$configPath' 中的 VcpCode、DisplayPortInputValue 和 HdmiInputValue 必须是整数。"
    exit 2
}

if ($displayPortInputValue -eq $hdmiInputValue) {
    Write-Error "配置文件 '$configPath' 中的 DisplayPortInputValue 和 HdmiInputValue 不能相同。"
    exit 2
}

$targetSerialNumber = ([string]$configuration.TargetSerialNumber).Trim()
$monitorIdentifier = ([string]$configuration.MonitorIdentifier).Trim()
$logPathValue = ([string]$configuration.LogPath).Trim()

if ([System.IO.Path]::IsPathRooted($logPathValue)) {
    Write-Error "配置文件 '$configPath' 中的 LogPath 必须是相对于项目目录的路径。"
    exit 2
}

$LogPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $logPathValue))
$controlMyMonitor = Join-Path $PSScriptRoot 'tools\ControlMyMonitor\ControlMyMonitor.exe'
$usbLogView = Join-Path $PSScriptRoot 'tools\USBLogView\USBLogView.exe'
$usbLogViewConfig = Join-Path $PSScriptRoot 'tools\USBLogView\USBLogView.cfg'

foreach ($requiredFile in @($controlMyMonitor, $usbLogView, $usbLogViewConfig)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        Write-Error "缺少所需文件：$requiredFile"
        exit 2
    }
}

$logDirectory = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
    Write-Error "未找到日志目录：$logDirectory"
    exit 2
}

# USBLogView 会向此文件追加事件；先创建文件，再从末尾开始监听。
if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
    New-Item -ItemType File -Path $LogPath | Out-Null
}

Write-Host "正在监听 USB 序列号 $targetSerialNumber 的插拔事件；按 Ctrl+C 停止。"

Get-Content -LiteralPath $LogPath -Tail 0 -Wait | ForEach-Object {
    $line = $_
    # 一次切换可能产生 Hub 和 HID 子设备事件；只匹配配置中的序列号。
    if ($line.IndexOf($targetSerialNumber, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $line -match '(?i)\b(Unplug|Plug)\b') {
        $action = $Matches[1]
        $inputValue = if ($action -ieq 'Plug') { $displayPortInputValue } else { $hdmiInputValue }

        # VCP 60 用于切换显示器输入源。
        & $controlMyMonitor /SetValue $monitorIdentifier $vcpCode $inputValue
        $exitCode = $LASTEXITCODE
        if (-not [string]::IsNullOrWhiteSpace([string]$exitCode) -and [int]$exitCode -ne 0) {
            Write-Warning "ControlMyMonitor 切换失败，退出码为 $exitCode；USB 事件：$action。"
        }
    }
}
