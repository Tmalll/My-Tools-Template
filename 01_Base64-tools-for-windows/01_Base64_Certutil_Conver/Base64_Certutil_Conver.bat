@echo off
setlocal enabledelayedexpansion

echo.
echo.
echo Certutil Conver
echo.
echo 编码限制: 小于70MB
echo 解码限制: 小于 2GB 的二进制文件.
echo 解码限制: 小于 2.66GB 的 Base64 文件.
echo.
echo.


:: 检查是否有拖放文件
if "%~1"=="" (
    echo 请把文件拖放到此脚本上
    pause
    exit /b
)

:: 记录开始时间（秒）
for /f %%T in ('powershell -NoProfile -Command "[int](Get-Date -UFormat %%s)"') do set startTime=%%T

:: 遍历所有拖放文件
for %%F in (%*) do (
    set "fullpath=%%~fF"
    set "filename=%%~nxF"
    set "ext=%%~xF"
    
    if /i "!ext!"==".b64" (
        
        echo 解码中: "%%F"
        certutil -f -decode "%%~fF" "%%~dpnF" >NUL 2>&1
        echo 解码完成: "%%~dpnF"
        
    ) else (
        
        echo 编码中: "%%~dpnF"
        set "outfile=%%~dpnxF.b64"
        certutil -f -encode "%%~fF" "!outfile!" >NUL 2>&1
        echo 编码完成: "!outfile!"
        
    )
)

:: 记录结束时间（秒）
for /f %%T in ('powershell -NoProfile -Command "[int](Get-Date -UFormat %%s)"') do set endTime=%%T
:: 计算耗时（秒）
set /a elapsed=%endTime%-%startTime%
echo 所有文件处理完成!
echo 总耗时: %elapsed% 秒
timeout /t 5 >nul
pause
exit
