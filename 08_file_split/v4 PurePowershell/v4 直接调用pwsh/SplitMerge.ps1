param(
    [string[]]$Files = $args
)

# ================= 用户设置 =================
$CHUNK_MB   = 100    # 每块大小（单位MB）
$BUF_MB     = 32     # 缓冲区大小（单位MB）
$FS_BUF_MB  = 32     # FileStream 内部缓冲（单位MB）
$PART_PAD   = 3      # 分块编号位数
# ============================================

# ================= 文件分割 =================
function Split-File {
    param([string]$File, [long]$ChunkSize, [int]$BufSize, [int]$FSBufSize, [int]$Pad, [string]$LogFile)

    Log ("Start splitting file: {0}" -f $File) $LogFile
    $fs = [IO.File]::OpenRead($File)
    $buf = New-Object byte[] $BufSize
    $total = [math]::Ceiling($fs.Length / $ChunkSize)
    $idx = 1

    while ($fs.Position -lt $fs.Length) {
        $suffix = $idx.ToString("D$Pad")
        $part = Join-Path (Split-Path $File -Parent) ("{0}.part{1}" -f (Split-Path $File -Leaf), $suffix)
        $out = New-Object IO.FileStream($part, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None, $FSBufSize)
        $remaining = [math]::Min($ChunkSize, $fs.Length - $fs.Position)

        while ($remaining -gt 0) {
            $toRead = [math]::Min($buf.Length, $remaining)
            $read = $fs.Read($buf,0,$toRead)
            if ($read -le 0) { break }
            $out.Write($buf,0,$read)
            $remaining -= $read
        }

        $out.Close()
        Log ("Split Writing chunk {0}/{1} -> {2}" -f $idx, $total, $part) $LogFile
        $idx++
    }

    $fs.Close()
    Log ("Split complete, total {0} chunks." -f ($idx-1)) $LogFile
}

# ================= 文件合并 =================
function Merge-Parts {
    param([string]$File, [int]$BufSize, [int]$FSBufSize, [int]$Pad, [string]$LogFile)

    $basename = [IO.Path]::GetFileName($File)
    $dir = [IO.Path]::GetDirectoryName($File)
    $outName = [IO.Path]::GetFileNameWithoutExtension($basename)
    $outFile = Join-Path $dir $outName

    if (Test-Path $outFile) { Remove-Item $outFile }

    Log ("Start merging file: {0}" -f $File) $LogFile

    $buf = New-Object byte[] $BufSize
    $parts = Get-ChildItem -LiteralPath $dir -Filter "$outName.part*" | Sort-Object Name
    $out = New-Object IO.FileStream($outFile,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None,$FSBufSize)
    $idx = 0

    foreach ($p in $parts) {
        $fs = [IO.File]::OpenRead($p.FullName)

        while (($read = $fs.Read($buf,0,$buf.Length)) -gt 0) {
            $out.Write($buf,0,$read)
        }

        $fs.Close()
        $idx++
        Log ("Merging chunk {0}: {1}" -f $idx, $p.FullName) $LogFile
    }

    $out.Close()
    Log ("Merge complete, total {0} chunks -> {1}" -f $idx, $outFile) $LogFile
}

# ================= 日志函数 =================
function Log($msg, $LogFile) {
    $msg | Tee-Object -FilePath $LogFile -Append
}

# ================= 主逻辑 =================
if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "Please drag and drop files onto this script or its shortcut."
    Write-Host "Wait 5 seconds or press any key to skip..." ; cmd /c "timeout /t 5 >nul"
    cmd /c pause
    exit
}

$CHUNK_SIZE  = $CHUNK_MB * 1MB
$BUF_SIZE    = $BUF_MB * 1MB
$FS_BUF_SIZE = $FS_BUF_MB * 1MB
$startTime = Get-Date

foreach ($file in $Files) {
    $path     = [IO.Path]::GetFullPath($file)
    $filename = [IO.Path]::GetFileName($file)
    $dir      = [IO.Path]::GetDirectoryName($file)
    $LOGFILE  = Join-Path $dir "SplitMerge.log"

    if (Test-Path $LOGFILE) { Remove-Item $LOGFILE -Force }

    # 在日志开头记录 PowerShell 版本和脚本开始时间
    $ver = $PSVersionTable.PSVersion.ToString()
    $hostExe = (Get-Process -Id $PID).Path
    Log ("PowerShell version: {0}" -f $ver) $LOGFILE
    Log ("Host executable: {0}" -f $hostExe) $LOGFILE
    Log ("Script started at: {0}" -f $startTime) $LOGFILE
    Log "==========================================" $LOGFILE

    Log "`n==========================" $LOGFILE
    Log ("Processing file: {0}" -f $path) $LOGFILE
    Log "==========================" $LOGFILE

    if ($filename -like "*.part*") {
        Log "Detected .part file, starting merge..." $LOGFILE
        Merge-Parts -File $path -BufSize $BUF_SIZE -FSBufSize $FS_BUF_SIZE -Pad $PART_PAD -LogFile $LOGFILE
    } else {
        Log "Detected normal file, starting split..." $LOGFILE
        Split-File -File $path -ChunkSize $CHUNK_SIZE -BufSize $BUF_SIZE -FSBufSize $FS_BUF_SIZE -Pad $PART_PAD -LogFile $LOGFILE
    }

    $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
    Log "All files processed!" $LOGFILE
    Log ("Total elapsed time: {0} seconds" -f $elapsed) $LOGFILE

    # 显示日志
    Write-Host ""
    Get-Content $LOGFILE
    Write-Host ""
    Write-Host "Wait 5 seconds or press any key to skip..." ; cmd /c "timeout /t 5 >nul"
    cmd /c pause
}
