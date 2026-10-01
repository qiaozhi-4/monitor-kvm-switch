@echo off
rem 在本脚本范围内启用 CMD 命令扩展，不改动外层命令提示符的环境。
setlocal EnableExtensions

rem ControlMyMonitor 用显示器标识定位要切换输入源的屏幕。
set "MONITOR_ID=VG27AQML1A"
rem 先清空程序路径，后面会依次尝试两个常见位置。
set "CMM="

rem 优先使用脚本同目录的副本，方便整个目录一起移动。
if exist "%~dp0ControlMyMonitor.exe" set "CMM=%~dp0ControlMyMonitor.exe"
rem 同目录没有时，再从 PATH 环境变量列出的目录中查找。
if not defined CMM (
  rem where 可能返回多个结果；只保存第一个找到的可执行文件。
  for /f "delims=" %%I in ('where ControlMyMonitor.exe 2^>nul') do if not defined CMM set "CMM=%%~fI"
)

rem 两处都找不到就提示安装位置，并用 127 表示依赖程序缺失。
if not defined CMM (
  echo ControlMyMonitor.exe was not found.
  echo Put it beside this script or add its folder to PATH.
  exit /b 127
)

rem 写入显示器 VCP 0x60（Input Select）；本显示器的值 17 对应 Mac 所在的 HDMI 输入。
"%CMM%" /SetValue "%MONITOR_ID%" 60 17
rem 立即保存切换命令的退出码，后续输出信息可能改变 ERRORLEVEL。
set "RC=%ERRORLEVEL%"
rem 非 0 表示切换失败：显示错误码，并将同一错误码交还给调用方。
if not "%RC%"=="0" (
  echo ControlMyMonitor failed with exit code %RC%.
  exit /b %RC%
)

rem 命令成功后输出目标输入源，并以 0 表示成功结束。
echo Sent HDMI/Mac input selection to %MONITOR_ID% (VCP 0x60=17).
exit /b 0
