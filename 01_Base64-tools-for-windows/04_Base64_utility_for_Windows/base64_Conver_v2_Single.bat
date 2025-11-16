@echo off
setlocal enabledelayedexpansion

echo.
echo.
echo Base64_utility_for_Windows
echo.
echo 编码限制: 已测试5G+
echo 解码限制: 已测试5G+
echo 如要解码 certutil 编码的文件, 需手动去除首尾行
echo.
echo.

:: 在批处理里定义 bufferSize（单位 MB）这里就是定义一行有多少数据.
:: 如果想要被 certutil 解码 所填值必须是3的倍数 1 / 3 / 6 / 9 / 12 / ...
set bufferSize=1

:: 计算字节数：bufferSize × 1048576
set /a bufferBytes=%bufferSize%*1048576


:: 当前目录下的 base64.exe
set "BASE64_EXE=%~dp0base64.exe"

:: 检查 base64.exe 是否存在
if not exist "%BASE64_EXE%" (
    echo [错误] base64.exe 未找到，请确保它与脚本在同一目录下
    pause
    exit /b
)

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
        echo 解码中: %%F
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$exe='%BASE64_EXE%'; $in='%%~fF'; $out='%%~dpnF';" ^
        "try {" ^
        "  $psi=New-Object System.Diagnostics.ProcessStartInfo;" ^
        "  $psi.FileName=$exe;" ^
        "  $psi.Arguments='-d ' + ('\"' + $in + '\"');" ^
        "  $psi.UseShellExecute=$false;" ^
        "  $psi.RedirectStandardOutput=$true;" ^
        "  $proc=[System.Diagnostics.Process]::Start($psi);" ^
        "  $fs=[System.IO.File]::Open($out,'Create');" ^
        "  $buf=New-Object byte[] %bufferBytes%;" ^
        "  while(($r=$proc.StandardOutput.BaseStream.Read($buf,0,$buf.Length)) -gt 0){ $fs.Write($buf,0,$r) };" ^
        "  $fs.Close(); $proc.WaitForExit()" ^
        "} catch { Write-Host '出错:' $_; pause }"
        echo 解码完成: %%~dpnF
    ) else (
        echo 编码中: %%~dpnF
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$exe='%BASE64_EXE%'; $in='%%~fF'; $out='%%~dpnxF.b64';" ^
        "try {" ^
        "  $psi=New-Object System.Diagnostics.ProcessStartInfo;" ^
        "  $psi.FileName=$exe;" ^
        "  $psi.Arguments='-w0 ' + ('\"' + $in + '\"');" ^
        "  $psi.UseShellExecute=$false;" ^
        "  $psi.RedirectStandardOutput=$true;" ^
        "  $proc=[System.Diagnostics.Process]::Start($psi);" ^
        "  $fs=[System.IO.File]::Open($out,'Create');" ^
        "  $buf=New-Object byte[] %bufferBytes%;" ^
        "  while(($r=$proc.StandardOutput.BaseStream.Read($buf,0,$buf.Length)) -gt 0){ $fs.Write($buf,0,$r) };" ^
        "  $fs.Close(); $proc.WaitForExit()" ^
        "} catch { Write-Host '出错:' $_; pause }"
        echo 编码完成: %%~dpnxF.b64
    )
)

:: 记录结束时间
for /f %%T in ('powershell -NoProfile -Command "[int](Get-Date -UFormat %%s)"') do set endTime=%%T
set /a elapsed=%endTime%-%startTime%
echo 所有文件处理完成!
echo 总耗时: %elapsed% 秒
pause
exit
