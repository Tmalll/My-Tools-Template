@echo off
setlocal enabledelayedexpansion

set "file=5120m"
set "block=100M"
set /a i=1

:: ================= 记录开始时间 毫秒级 =================
for /f %%T in ('powershell -NoProfile -Command "[int64](Get-Date).ToUniversalTime().Ticks/10000"') do set startTime=%%T


:loop
:: 生成文件名：原文件名.partXYZ.b64
set "num=00!i!"
set "num=!num:~-3!"
set "fname=%file%.part!num!"

set /a skip=!i!-1
coreutils.exe dd if=%file% bs=%block% count=1 skip=!skip! 2>nul | coreutils.exe base64 -w 0 > "!fname!.b64"

for %%A in ("!fname!.b64") do (
    if %%~zA==0 (
        del /q "%%A"
        goto done
    )
)

echo 生成 !fname!.b64
set /a i+=1
goto loop

:done
set /a i-=1

:: ================== 记录结束时间 毫秒级 ==================
powershell -NoProfile -Command "$elapsed=[int64](Get-Date).ToUniversalTime().Ticks/10000 - %startTime%; Write-Host ('总计耗时 {0:F3} 秒' -f ($elapsed/1000.0))"
echo. && echo 所有文件处理完成! && echo.

echo 完成。共生成：%i% 块。
pause
exit

