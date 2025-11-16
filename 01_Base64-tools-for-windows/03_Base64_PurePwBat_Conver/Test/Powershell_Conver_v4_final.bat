@echo off
setlocal enabledelayedexpansion


echo.
echo.
echo Powershell Conver
echo.
echo 编码限制: 最大测试5G编码成功
echo 解码限制: 最大测试5G解码成功
echo 如要解码 certutil 编码的文件, 需要手动去除首尾行
echo.
echo.


:: 可调参数（单位：字节）
:: 建议范围：
::   bufferSize   → 1MB ~ 16MB (1048576 ~ 16777216)，越大循环次数越少，但内存占用增加
::   writerBuffer → 64KB ~ 1MB (65536 ~ 1048576)，写缓冲，越大磁盘写入效率越高
::   readerBuffer → 64KB ~ 1MB (65536 ~ 1048576)，读缓冲，越大磁盘读取效率越高
set bufferSize=1048576
set writerBuffer=1048576
set readerBuffer=1048576

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
        powershell -NoProfile -Command ^
        "$infile='%%~fF';" ^
        "$basename=[System.IO.Path]::GetFileNameWithoutExtension($infile);" ^
        "$outdir=[System.IO.Path]::GetDirectoryName($infile);" ^
        "$outfile=[System.IO.Path]::Combine($outdir,$basename);" ^
        "$readerBuffer=%readerBuffer%;" ^
        "$writerBuffer=%writerBuffer%;" ^
        "$input=[System.IO.StreamReader]::new($infile,[System.Text.Encoding]::ASCII,$false,$readerBuffer);" ^
        "$fs=[System.IO.FileStream]::new($outfile,[System.IO.FileMode]::Create);" ^
        "$output=[System.IO.BufferedStream]::new($fs,$writerBuffer);" ^
        "while(-not $input.EndOfStream){" ^
        "  $chunk=$input.ReadLine();" ^
        "  if([string]::IsNullOrWhiteSpace($chunk)){continue};" ^
        "  $bytes=[Convert]::FromBase64String($chunk);" ^
        "  $output.Write($bytes,0,$bytes.Length)" ^
        "};" ^
        "$input.Close();$output.Close();"
        echo 解码完成: %%~dpnF
        
    ) else (
        
        echo 编码中: "%%~dpnF" 多行 Base64 版本
        set "outfile=%%~dpnxF.b64"
        powershell -NoProfile -Command ^
        "$infile='%%~fF';" ^
        "$outfile='%%~dpnxF.b64';" ^
        "$bufferSize=%bufferSize%;" ^
        "$writerBuffer=%writerBuffer%;" ^
        "$input=[System.IO.File]::OpenRead($infile);" ^
        "$output=[System.IO.StreamWriter]::new($outfile,$false,[System.Text.Encoding]::ASCII,$writerBuffer);" ^
        "$buffer=New-Object byte[] $bufferSize;" ^
        "while(($read=$input.Read($buffer,0,$buffer.Length)) -gt 0){" ^
        "  $chunk=[Convert]::ToBase64String($buffer,0,$read);" ^
        "  $output.WriteLine($chunk)" ^
        "};" ^
        "$input.Close();$output.Close();"
        echo 编码完成: "%%~dpnxF.b64" 单行 Base64 版本
    )
)

:: 记录结束时间（秒）
for /f %%T in ('powershell -NoProfile -Command "[int](Get-Date -UFormat %%s)"') do set endTime=%%T
:: 计算耗时（秒）
set /a elapsed=%endTime%-%startTime%
echo 所有文件处理完成!
echo 总耗时: %elapsed% 秒
timeout /t 5 >nul
exit
