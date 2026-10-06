@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "LAUNCHER=%~dp0start.ps1"
if not exist "%LAUNCHER%" (
    echo Missing start.ps1.
    exit /b 2
)

if /I "%~1"=="--run" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -Run
) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%"
)
exit /b %ERRORLEVEL%
