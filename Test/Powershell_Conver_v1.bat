@echo off
setlocal enabledelayedexpansion

:: 检查是否有拖放文件
if "%~1"=="" (
    echo 请把文件拖放到此脚本上
    pause
    exit /b
)

:: 遍历所有拖放文件
for %%F in (%*) do (
    set "fullpath=%%~fF"
    set "filename=%%~nxF"
    set "ext=%%~xF"

    if /i "!ext!"==".b64" (
        :: 解码 .b64 文件
        powershell -NoProfile -Command ^
        "$infile='%%~fF';" ^
        "$b64=[System.IO.File]::ReadAllText($infile);" ^
        "$basename=[System.IO.Path]::GetFileNameWithoutExtension($infile);" ^
        "$outdir=[System.IO.Path]::GetDirectoryName($infile);" ^
        "$outfile=[System.IO.Path]::Combine($outdir,$basename);" ^
        "[System.IO.File]::WriteAllBytes($outfile,[Convert]::FromBase64String($b64));"
        echo 解码完成: %%F
    ) else (
        :: 编码为 Base64，不换行，最小膨胀
        set "outfile=%%~dpnxF.b64"
        powershell -NoProfile -Command ^
        "$bytes=[System.IO.File]::ReadAllBytes('%%~fF');" ^
        "$b64=[Convert]::ToBase64String($bytes);" ^
        "[System.IO.File]::WriteAllText('%%~dpnxF.b64',$b64,[System.Text.Encoding]::ASCII);"
        echo 编码完成: %%F
    )
)

echo 所有文件处理完成!
timeout /t 1 >nul
exit


