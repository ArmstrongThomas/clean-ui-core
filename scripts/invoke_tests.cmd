@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0invoke_tests.ps1" %*
exit /b %ERRORLEVEL%

