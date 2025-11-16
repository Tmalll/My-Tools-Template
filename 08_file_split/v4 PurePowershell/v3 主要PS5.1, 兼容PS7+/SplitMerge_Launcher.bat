@echo off
setlocal enabledelayedexpansion

:: 1 = 强制使用 PowerShell 7 (pwsh)
:: 0 = 使用系统自带 PowerShell 5.1
set USE_PWSH=0

:: 日志文件
del /s /q SplitMerge.log
set LOGFILE=SplitMerge.log

if "%~1"=="" (
    echo Please drag and drop files onto this batch file! >> "%LOGFILE%"
    echo Please drag and drop files onto this batch file!
    pause
    exit /b
)

:: 根据变量选择 PowerShell 版本
if "%USE_PWSH%"=="1" (
    set "PSCMD=pwsh.exe"
    echo Using PowerShell 7+ pwsh >> "%LOGFILE%"
    echo Using PowerShell 7+ pwsh
) else (
    set "PSCMD=powershell.exe"
    echo Using system PowerShell 5.1 >> "%LOGFILE%"
    echo Using system PowerShell 5.1
)

echo Command: %PSCMD% >> "%LOGFILE%"
echo Command: %PSCMD%

:: 执行 PS 脚本，输出同时追加到日志
for %%F in (%*) do (
    "%PSCMD%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0SplitMerge.ps1" "%%~fF" >> "%LOGFILE%" 2>&1
)

echo All .bat tasks completed! >> "%LOGFILE%"
echo All .bat tasks completed!
echo.

cls
echo.
type "%LOGFILE%"
echo.

pause
exit /b
