@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify_source_tree.ps1" %*
exit /b %ERRORLEVEL%

