@echo off
setlocal
if "%~1"=="" (
  echo Usage: build_example.cmd EXAMPLE_PATH [additional PowerShell arguments]
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_example.ps1" -ExamplePath "%~1" %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%

