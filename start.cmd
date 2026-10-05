@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "PROJECT_DIR=%~dp0"
set "USBLOGVIEW_DIR=%PROJECT_DIR%tools\USBLogView"
set "USBLOGVIEW_EXE=%USBLOGVIEW_DIR%\USBLogView.exe"
set "USBLOGVIEW_CONFIG=%USBLOGVIEW_DIR%\USBLogView.cfg"
set "CONTROLMYMONITOR_EXE=%PROJECT_DIR%tools\ControlMyMonitor\ControlMyMonitor.exe"
set "LISTENER_SCRIPT=%PROJECT_DIR%usb_event_switch.ps1"
set "SWITCH_CONFIG=%PROJECT_DIR%switch-config.psd1"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "AUTOSTART_LINK=%STARTUP_DIR%\Monitor KVM Switch.lnk"
set "INTERACTIVE=1"

if /I "%~1"=="--run" set "INTERACTIVE=0"
if "%INTERACTIVE%"=="0" goto run

:menu
cls
echo USB 事件自动切换
echo ================================
if exist "%AUTOSTART_LINK%" (
    echo 开机自启动：已启用（当前用户登录时运行）
) else (
    echo 开机自启动：未启用
)
echo.
echo 1. 现在启动监听
echo 2. 启用当前用户登录自启动
echo 3. 禁用当前用户登录自启动
echo 4. 退出
choice /C 1234 /N /M "请选择 [1-4]："
if errorlevel 4 goto exit
if errorlevel 3 goto disable_autostart
if errorlevel 2 goto enable_autostart
if errorlevel 1 goto run
goto menu

:enable_autostart
if not exist "%STARTUP_DIR%" mkdir "%STARTUP_DIR%" 2>nul
if not exist "%STARTUP_DIR%" (
    echo 无法创建当前用户的启动文件夹：
    echo %STARTUP_DIR%
    pause
    goto menu
)
set "AUTOSTART_TARGET=%~f0"
set "AUTOSTART_WORKDIR=%PROJECT_DIR%"
set "AUTOSTART_COMSPEC=%ComSpec%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $shell = New-Object -ComObject WScript.Shell; $shortcut = $shell.CreateShortcut($env:AUTOSTART_LINK); $shortcut.TargetPath = $env:AUTOSTART_COMSPEC; $quote = [char]34; $shortcut.Arguments = '/c ' + $quote + $quote + $env:AUTOSTART_TARGET + $quote + ' --run' + $quote; $shortcut.WorkingDirectory = $env:AUTOSTART_WORKDIR; $shortcut.Description = 'Monitor KVM USB event switch'; $shortcut.Save()"
if errorlevel 1 (
    echo 创建自启动快捷方式失败。
) else (
    echo 已启用：当前 Windows 用户登录时会自动开始监听。
)
pause
goto menu

:disable_autostart
if exist "%AUTOSTART_LINK%" (
    del /F /Q "%AUTOSTART_LINK%"
    if exist "%AUTOSTART_LINK%" (
        echo 删除自启动快捷方式失败：%AUTOSTART_LINK%
    ) else (
        echo 已禁用自启动。当前正在运行的监听不会因此停止。
    )
) else (
    echo 自启动当前未启用。
)
pause
goto menu

:run
if not exist "%SWITCH_CONFIG%" (
    echo 缺少配置文件：%SWITCH_CONFIG%
    goto error
)
if not exist "%USBLOGVIEW_EXE%" (
    echo 缺少 USBLogView：%USBLOGVIEW_EXE%
    goto error
)
if not exist "%USBLOGVIEW_CONFIG%" (
    echo 缺少 USBLogView 配置：%USBLOGVIEW_CONFIG%
    goto error
)
if not exist "%CONTROLMYMONITOR_EXE%" (
    echo 缺少 ControlMyMonitor：%CONTROLMYMONITOR_EXE%
    goto error
)
if not exist "%LISTENER_SCRIPT%" (
    echo 缺少监听脚本：%LISTENER_SCRIPT%
    goto error
)

echo 正在启动 USBLogView 和事件监听。关闭监听窗口即可停止监听。
start "" /D "%USBLOGVIEW_DIR%" "%USBLOGVIEW_EXE%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LISTENER_SCRIPT%"
set "LISTENER_EXIT_CODE=%ERRORLEVEL%"
if not "%LISTENER_EXIT_CODE%"=="0" echo 监听已结束，退出码：%LISTENER_EXIT_CODE%
if "%INTERACTIVE%"=="1" (
    pause
    goto menu
)
if not "%LISTENER_EXIT_CODE%"=="0" pause
exit /b %LISTENER_EXIT_CODE%

:error
if "%INTERACTIVE%"=="1" (
    pause
    goto menu
)
echo 请检查项目文件和 switch-config.psd1，然后重试。
pause
exit /b 2

:exit
exit /b 0
