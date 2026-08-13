@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0make_lock.ps1" %*
exit /b %ERRORLEVEL%

