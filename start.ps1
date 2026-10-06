param(
    [switch]$Run
)

$projectDirectory = $PSScriptRoot
$usbLogViewDirectory = Join-Path $projectDirectory 'tools\USBLogView'
$usbLogView = Join-Path $usbLogViewDirectory 'USBLogView.exe'
$usbLogViewConfig = Join-Path $usbLogViewDirectory 'USBLogView.cfg'
$controlMyMonitor = Join-Path $projectDirectory 'tools\ControlMyMonitor\ControlMyMonitor.exe'
$listenerScript = Join-Path $projectDirectory 'usb_event_switch.ps1'
$switchConfig = Join-Path $projectDirectory 'switch-config.psd1'
$startupDirectory = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$autostartLink = Join-Path $startupDirectory 'Monitor KVM Switch.lnk'

function Invoke-Listener {
    $requiredFiles = @(
        $switchConfig,
        $usbLogView,
        $usbLogViewConfig,
        $controlMyMonitor,
        $listenerScript
    )
    $missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
    if ($missingFiles.Count -gt 0) {
        Write-Host '缺少所需文件：' -ForegroundColor Red
        $missingFiles | ForEach-Object { Write-Host "  $_" }
        return 2
    }

    Write-Host '正在启动 USBLogView 和事件监听。关闭监听窗口即可停止监听。'
    try {
        Start-Process -FilePath $usbLogView -WorkingDirectory $usbLogViewDirectory
    }
    catch {
        Write-Host "无法启动 USBLogView：$($_.Exception.Message)" -ForegroundColor Red
        return 2
    }

    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $listenerScript
    $listenerExitCode = $LASTEXITCODE
    if ($listenerExitCode -ne 0) {
        Write-Host "监听已结束，退出码：$listenerExitCode" -ForegroundColor Yellow
    }
    return $listenerExitCode
}

function Enable-Autostart {
    try {
        New-Item -ItemType Directory -Path $startupDirectory -Force | Out-Null
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($autostartLink)
        $shortcut.TargetPath = $env:ComSpec
        $quote = [char]34
        $shortcut.Arguments = '/c ' + $quote + $quote + (Join-Path $projectDirectory 'start.cmd') + $quote + ' --run' + $quote
        $shortcut.WorkingDirectory = $projectDirectory
        $shortcut.Description = 'Monitor KVM USB event switch'
        $shortcut.Save()
        Write-Host '已启用：当前 Windows 用户登录时会自动开始监听。' -ForegroundColor Green
    }
    catch {
        Write-Host "创建自启动快捷方式失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}

function Disable-Autostart {
    if (-not (Test-Path -LiteralPath $autostartLink -PathType Leaf)) {
        Write-Host '自启动当前未启用。'
        return
    }

    try {
        Remove-Item -LiteralPath $autostartLink -Force
        Write-Host '已禁用自启动。当前正在运行的监听不会因此停止。' -ForegroundColor Green
    }
    catch {
        Write-Host "删除自启动快捷方式失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($Run) {
    $exitCode = Invoke-Listener
    if ($exitCode -ne 0) {
        [void](Read-Host '请检查项目文件和 switch-config.psd1，然后按 Enter 关闭此窗口')
    }
    exit $exitCode
}

while ($true) {
    Clear-Host
    Write-Host 'USB 事件自动切换'
    Write-Host '================================'
    if (Test-Path -LiteralPath $autostartLink -PathType Leaf) {
        Write-Host '开机自启动：已启用（当前用户登录时运行）'
    }
    else {
        Write-Host '开机自启动：未启用'
    }
    Write-Host ''
    Write-Host '1. 现在启动监听'
    Write-Host '2. 启用当前用户登录自启动'
    Write-Host '3. 禁用当前用户登录自启动'
    Write-Host '4. 退出'

    $menuChoice = Read-Host '请选择 [1-4]'
    if ($menuChoice -eq '1') {
        [void](Invoke-Listener)
        [void](Read-Host '按 Enter 返回菜单')
        continue
    }
    if ($menuChoice -eq '2') {
        Enable-Autostart
        [void](Read-Host '按 Enter 返回菜单')
        continue
    }
    if ($menuChoice -eq '3') {
        Disable-Autostart
        [void](Read-Host '按 Enter 返回菜单')
        continue
    }
    if ($menuChoice -eq '4') {
        exit 0
    }

    Write-Host '请输入 1、2、3 或 4。' -ForegroundColor Yellow
    [void](Read-Host '按 Enter 返回菜单')
}
