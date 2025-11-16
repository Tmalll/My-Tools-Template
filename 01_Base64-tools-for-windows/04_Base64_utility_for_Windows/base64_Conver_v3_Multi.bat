@echo on
setlocal EnableDelayedExpansion

echo ==========================
echo Base64 Utility for Windows (大文件并行安全版)
echo 拖放文件即可编码/解码
echo ==========================
echo.

:: base64.exe 路径（与本脚本同目录）
set "BASE64_EXE=%~dp0base64.exe"

if not exist "%BASE64_EXE%" (
    echo [错误] base64.exe 未找到，请确保它在本脚本目录下
    pause
    exit /b
)

:: 每个文件分成多少块
set "PARTS=10"

:: 拖放文件检查
if "%~1"=="" (
    echo 请把文件拖放到此脚本上
    pause
    exit /b
)

:nextfile
set "FILE=%~1"
set "FILENAME=%~nx1"
set "EXT=%~x1"
set "DIR=%~dp1"

echo.
echo ==========================
echo 处理文件: %FILE%
echo ==========================

:: 创建临时分块目录
set "TMPDIR=%DIR%~b64tmp_%FILENAME%"
if exist "%TMPDIR%" rd /s /q "%TMPDIR%"
mkdir "%TMPDIR%" || (
    echo [错误] 无法创建临时目录: "%TMPDIR%"
    pause
    exit /b
)

:: 使用 PowerShell 分块（避免批处理整数溢出）
echo 正在分块...
powershell -NoProfile -Command ^
  "$path = [IO.Path]::GetFullPath('%FILE%');" ^
  "$outDir = [IO.Path]::GetFullPath('%TMPDIR%');" ^
  "$fs = [IO.File]::OpenRead($path);" ^
  "$parts = %PARTS%;" ^
  "if ($parts -lt 1) { throw 'PARTS must be >= 1'; }" ^
  "$chunk = [long][math]::Ceiling($fs.Length / [double]$parts);" ^
  "for ($i=0; $i -lt $parts; $i++) {" ^
  "  $offset = [long]$i * $chunk;" ^
  "  if ($offset -ge $fs.Length) { break }" ^
  "  $len = [long][math]::Min($chunk, $fs.Length - $offset);" ^
  "  $buf = New-Object byte[] $len;" ^
  "  $fs.Seek($offset, [IO.SeekOrigin]::Begin) | Out-Null;" ^
  "  [void]$fs.Read($buf, 0, $len);" ^
  "  $partPath = [IO.Path]::Combine($outDir, 'part' + $i);" ^
  "  [IO.File]::WriteAllBytes($partPath, $buf);" ^
  "}" ^
  "$fs.Close()"

if errorlevel 1 (
    echo [错误] 分块失败。
    rd /s /q "%TMPDIR%"
    pause
    exit /b
)

:: 判断编码或解码
if /I "%EXT%"==".b64" (
    echo 解码中...
    for /L %%i in (0,1,%PARTS%-1) do (
        if exist "%TMPDIR%\part%%i" (
            start "" /b cmd /c ""%BASE64_EXE%" -d "%TMPDIR%\part%%i" > "%TMPDIR%\part%%i.dec""
        )
    )
    :: 等待所有块完成
    :wait_decode
    set /a done=0
    for /L %%i in (0,1,%PARTS%-1) do (
        if exist "%TMPDIR%\part%%i.dec" set /a done+=1
    )
    if not !done!==%PARTS% (
        timeout /t 1 >nul
    goto wait_decode
    )
    :: 合并块
    copy /b NUL "%DIR%%FILENAME%.dec" >nul
    for /L %%i in (0,1,%PARTS%-1) do (
        if exist "%TMPDIR%\part%%i.dec" type "%TMPDIR%\part%%i.dec" >> "%DIR%%FILENAME%.dec"
    )
    echo 完成: %DIR%%FILENAME%.dec
) else (
    echo 编码中...
    for /L %%i in (0,1,%PARTS%-1) do (
        if exist "%TMPDIR%\part%%i" (
            start "" /b cmd /c ""%BASE64_EXE%" -w0 "%TMPDIR%\part%%i" > "%TMPDIR%\part%%i.b64""
        )
    )
    :: 等待所有块完成
    :wait_encode
    set /a done=0
    for /L %%i in (0,1,%PARTS%-1) do (
        if exist "%TMPDIR%\part%%i.b64" set /a done+=1
    )
    if not !done!==%PARTS% (
        timeout /t 1 >nul
        goto wait_encode
    )
    :: 合并块
    copy /b NUL "%DIR%%FILENAME%.b64" >nul
    for /L %%i in (0,1,%PARTS%-1) do (
        if exist "%TMPDIR%\part%%i.b64" type "%TMPDIR%\part%%i.b64" >> "%DIR%%FILENAME%.b64"
    )
    echo 完成: %DIR%%FILENAME%.b64
)

:: 删除临时目录
rd /s /q "%TMPDIR%"

shift
if not "%~1"=="" goto nextfile

echo.
echo 所有文件处理完成!
pause
