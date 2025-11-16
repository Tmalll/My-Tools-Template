@echo off
setlocal EnableDelayedExpansion

echo ==========================
echo File Split / Merge Tool (高速非阻塞版)
echo 拖放文件即可分割或合并
echo 注意: 路径中不能有 "^!" "^`" "^'" "^"" 等符号...
echo ==========================
echo.

:: ================= 用户设置 =================
set "CHUNK_MB=100"        :: 每块大小（MB）
set "BUF_MB=32"           :: 缓冲区大小（MB）
set "PART_PAD=3"          :: 分块编号位数
:: =============================================

if "%~1"=="" (
    echo 请把文件拖放到此脚本上
    pause
    exit /b
)

set /a CHUNK_SIZE=%CHUNK_MB%*1024*1024
set /a BUF_SIZE=%BUF_MB%*1024*1024

:: 记录开始时间
for /f %%T in ('powershell -NoProfile -Command "[Environment]::TickCount"') do set startTime=%%T

:nextfile
set "FILE=%~1"
set "FILENAME=%~nx1"
set "DIR=%~dp1"

echo.
echo ==========================
echo 处理文件: %FILE%
echo ==========================

echo %FILENAME% | find ".part" >nul
if %errorlevel%==0 (
    echo 检测到 .part 文件，开始合并...
    call :merge_parts "%FILE%"
) else (
    echo 检测到普通文件，准备分割...
    call :split_file "%FILE%"
)

shift
if not "%~1"=="" goto nextfile

:: 结束时间
for /f %%T in ('powershell -NoProfile -Command "[Environment]::TickCount"') do set endTime=%%T
set /a elapsedMs=endTime-startTime
set /a seconds=elapsedMs / 1000
set /a millis=elapsedMs %% 1000
if !millis! lss 10  set "millis=00!millis!"
if !millis! lss 100 set "millis=0!millis!"

echo 所有文件处理完成!
echo 总耗时: !seconds!.!millis! 秒
timeout /t 3 >nul
pause
exit /b



:: ==========================================================
:: 文件分割（异步高速版）
:: ==========================================================
:split_file
setlocal
set "SRC=%~1"

echo 分割大小: %CHUNK_MB% MB
echo 缓冲区大小: %BUF_MB% MB
echo 正在高速异步分割，请稍候...

powershell -NoProfile -Command ^
  "$path=[IO.Path]::GetFullPath('%SRC%');" ^
  "$outDir=[IO.Path]::GetDirectoryName($path);" ^
  "$chunk=[long]%CHUNK_SIZE%;" ^
  "$bufSize=%BUF_SIZE%;" ^
  "$buf=New-Object byte[] $bufSize;" ^
  "$pad=%PART_PAD%;" ^
  "$fs=[IO.File]::OpenRead($path);" ^
  "$total=[math]::Ceiling($fs.Length / $chunk);" ^
  "$idx=1;" ^
  "while($fs.Position -lt $fs.Length){" ^
  "  $suffix=$idx.ToString('D'+$pad);" ^
  "  $part=[IO.Path]::Combine($outDir,('{0}.part{1}' -f [IO.Path]::GetFileName($path),$suffix));" ^
  "  $out=[IO.File]::Open($part,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None);" ^
  "  $remaining=[long][math]::Min($chunk, $fs.Length - $fs.Position);" ^
  "  while($remaining -gt 0){" ^
  "    $toRead=[int][math]::Min($bufSize,$remaining);" ^
  "    $readTask=$fs.ReadAsync($buf,0,$toRead);" ^
  "    $readTask.Wait();" ^
  "    $read=$readTask.Result;" ^
  "    if($read -le 0){break};" ^
  "    $writeTask=$out.WriteAsync($buf,0,$read);" ^
  "    $writeTask.Wait();" ^
  "    $remaining-=$read;" ^
  "  }" ^
  "  $out.Close();" ^
  "  Write-Host ('正在写入分块 {0}/{1} -> {2}' -f $idx,$total,$part);" ^
  "  $idx++;" ^
  "}" ^
  "$fs.Close();" ^
  "Write-Host ('完成，共生成 {0} 个分块。' -f ($idx-1))"

echo 分割完成。
endlocal
goto :eof



:: ==========================================================
:: 文件合并（异步高速版）
:: ==========================================================
:merge_parts
setlocal EnableDelayedExpansion
set "FIRST=%~1"
set "DIR=%~dp1"
set "BASENAME=%~nx1"

for /f "delims=" %%a in ("%BASENAME%") do set "OUTNAME=%%~na"
set "OUTFILE=%DIR%%OUTNAME%"

echo.
echo 合并目标: "%OUTFILE%"
echo 缓冲区大小: %BUF_MB% MB
echo.

if exist "%OUTFILE%" del "%OUTFILE%"

powershell -NoProfile -Command ^
  "$outFile=[IO.Path]::GetFullPath('%OUTFILE%');" ^
  "$bufSize=%BUF_SIZE%;" ^
  "$buf=New-Object byte[] $bufSize;" ^
  "$parts=Get-ChildItem -LiteralPath '%DIR%' -Filter '%OUTNAME%.part*' | Sort-Object Name;" ^
  "$out=[IO.File]::Open($outFile,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None);" ^
  "$idx=0;" ^
  "foreach($p in $parts){" ^
  "  $fs=[IO.File]::OpenRead($p.FullName);" ^
  "  while(($readTask=$fs.ReadAsync($buf,0,$bufSize)).Result -gt 0){" ^
  "    $read=$readTask.Result;" ^
  "    $writeTask=$out.WriteAsync($buf,0,$read);" ^
  "    $writeTask.Wait();" ^
  "  }" ^
  "  $fs.Close();" ^
  "  $idx++;" ^
  "  Write-Host ('正在合并第 {0} 块: {1}' -f $idx,$p.FullName);" ^
  "}" ^
  "$out.Close();" ^
  "Write-Host ('合并完成，共 {0} 个分块 -> {1}' -f $idx,$outFile)"

endlocal
goto :eof
