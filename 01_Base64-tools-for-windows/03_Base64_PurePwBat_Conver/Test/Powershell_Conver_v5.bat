@echo off
setlocal enabledelayedexpansion

:: 可调参数（单位：字节）
:: 建议范围：
::    bufferSize   → 1MB ~ 16MB (1048576 ~ 16777216)，越大循环次数越少，但内存占用增加
::    writerBuffer → 64KB ~ 1MB (65536 ~ 1048576)，写缓冲，越大磁盘写入效率越高
::    readerBuffer → 64KB ~ 1MB (65536 ~ 1048576)，读缓冲，越大磁盘读取效率越高
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
        :: 解码 .b64 文件（流式）
        :: === 已修复的部分 ===
        :: 使用 CryptoStream 进行流式解码，可处理任意格式（包括单行）的 Base64 文件
        powershell -NoProfile -Command ^
        "$infile='%%~fF';" ^
        "$basename=[System.IO.Path]::GetFileNameWithoutExtension($infile);" ^
        "$outdir=[System.IO.Path]::GetDirectoryName($infile);" ^
        "$outfile=[System.IO.Path]::Combine($outdir,$basename);" ^
        "$readerBuffer=%readerBuffer%;" ^
        "$writerBuffer=%writerBuffer%;" ^
        "$inStream = [System.IO.FileStream]::new($infile, [System.IO.FileMode]::Open);" ^
        "$transform = [System.Security.Cryptography.FromBase64Transform]::new([System.Security.Cryptography.FromBase64TransformMode]::IgnoreWhiteSpaces);" ^
        "$cryptoStream = [System.Security.Cryptography.CryptoStream]::new($inStream, $transform, [System.Security.Cryptography.CryptoStreamMode]::Read);" ^
        "$input = [System.IO.BufferedStream]::new($cryptoStream, $readerBuffer);" ^
        "$fs = [System.IO.FileStream]::new($outfile, [System.IO.FileMode]::Create);" ^
        "$output = [System.IO.BufferedStream]::new($fs, $writerBuffer);" ^
        "$input.CopyTo($output);" ^
        "$output.Close();$input.Close();"
        echo 解码完成: %%F
    ) else (
        :: 编码为 Base64（流式，每行输出一段）
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
        echo 编码完成: %%F
    )
)

:: 记录结束时间（秒）
for /f %%T in ('powershell -NoProfile -Command "[int](Get-Date -UFormat %%s)"') do set endTime=%%T

:: 计算耗时（秒）
set /a elapsed=%endTime%-%startTime%

echo 所有文件处理完成!
echo 总耗时: %elapsed% 秒

timeout /t 1 >nul
pause
exit