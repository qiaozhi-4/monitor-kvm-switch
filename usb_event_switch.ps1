param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Plug', 'Unplug')]
    [string]$Action,

    [AllowEmptyString()]
    [string]$SerialNumber = ''
)

$targetSerialNumber = '117F313B3633'
if ($SerialNumber.Trim() -ine $targetSerialNumber) {
    exit 0
}

$controlMyMonitor = Join-Path $PSScriptRoot 'ControlMyMonitor.exe'
if (-not (Test-Path -LiteralPath $controlMyMonitor -PathType Leaf)) {
    exit 2
}

$inputValue = if ($Action -eq 'Plug') { 15 } else { 17 }
& $controlMyMonitor /SetValue 'VG27AQML1A' 60 $inputValue
exit $LASTEXITCODE
