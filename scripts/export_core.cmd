@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0export_core.ps1" %*
exit /b %ERRORLEVEL%

