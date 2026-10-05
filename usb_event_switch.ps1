param(
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = (Join-Path $PSScriptRoot 'usb-events.log')
)

$LogPath = [System.IO.Path]::GetFullPath($LogPath)
$targetSerialNumber = '117F313B3633'
$monitorIdentifier = '\\.\DISPLAY1\Monitor0'
$controlMyMonitor = Join-Path $PSScriptRoot 'ControlMyMonitor.exe'
if (-not (Test-Path -LiteralPath $controlMyMonitor -PathType Leaf)) {
    Write-Error "ControlMyMonitor.exe was not found: $controlMyMonitor"
    exit 2
}

$logDirectory = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
    Write-Error "Log directory was not found: $logDirectory"
    exit 2
}

# Create the file before USBLogView starts so the first appended event is observed.
if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
    New-Item -ItemType File -Path $LogPath | Out-Null
}

Get-Content -LiteralPath $LogPath -Tail 0 -Wait | ForEach-Object {
    $line = $_
    if ($line.IndexOf($targetSerialNumber, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $line -match '(?i)\b(Unplug|Plug)\b') {
        $action = $Matches[1]
        $inputValue = if ($action -ieq 'Plug') { 15 } else { 17 }

        & $controlMyMonitor /SetValue $monitorIdentifier 60 $inputValue
        $exitCode = $LASTEXITCODE
        if (-not [string]::IsNullOrWhiteSpace([string]$exitCode) -and [int]$exitCode -ne 0) {
            Write-Warning "ControlMyMonitor failed with exit code $exitCode for USB $action event."
        }
    }
}
