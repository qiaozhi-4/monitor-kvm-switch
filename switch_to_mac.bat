@echo off
setlocal EnableExtensions

set "MONITOR_ID=VG27AQML1A"
set "CMM="

if exist "%~dp0ControlMyMonitor.exe" set "CMM=%~dp0ControlMyMonitor.exe"
if not defined CMM (
  for /f "delims=" %%I in ('where ControlMyMonitor.exe 2^>nul') do if not defined CMM set "CMM=%%~fI"
)

if not defined CMM (
  echo ControlMyMonitor.exe was not found.
  echo Put it beside this script or add its folder to PATH.
  exit /b 127
)

"%CMM%" /SetValue "%MONITOR_ID%" 60 17
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo ControlMyMonitor failed with exit code %RC%.
  exit /b %RC%
)

echo Sent HDMI/Mac input selection to %MONITOR_ID% (VCP 0x60=17).
exit /b 0
