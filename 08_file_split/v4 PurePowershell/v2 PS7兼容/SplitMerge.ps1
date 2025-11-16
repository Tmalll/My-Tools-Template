param(
    [string[]]$Files = $args
)

# ================= 用户设置 =================
$CHUNK_MB   = 100    # 每块大小（单位MB）
$BUF_MB     = 32     # 缓冲区大小（单位MB）
$FS_BUF_MB  = 32     # FileStream 内部缓冲（单位MB）
$PART_PAD   = 3      # 分块编号位数
$SSD_MODE   = 1      # 是否启用SSD模式（异步 + 并行分割），0=关闭（HDD推荐），1=开启（SSD推荐）
# ============================================

# ================= 文件分割 =================
function Split-File {
    param([string]$File, [long]$ChunkSize, [int]$BufSize, [int]$FSBufSize, [int]$Pad)

    Write-Host ("Start splitting file: {0}" -f $File)
    $fs = [IO.File]::OpenRead($File)
    $buf = New-Object byte[] $BufSize
    $total = [math]::Ceiling($fs.Length / $ChunkSize)
    $idx = 1

    while ($fs.Position -lt $fs.Length) {
        $suffix = $idx.ToString("D$Pad")
        $part = Join-Path (Split-Path $File -Parent) ("{0}.part{1}" -f (Split-Path $File -Leaf), $suffix)
        $out = New-Object IO.FileStream($part, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None, $FSBufSize)
        $remaining = [math]::Min($ChunkSize, $fs.Length - $fs.Position)

        if ($SSD_MODE -eq 1 -and $PSVersionTable.PSVersion.Major -ge 7) {
            while ($remaining -gt 0) {
                $toRead = [math]::Min($buf.Length, $remaining)
                $read = $fs.ReadAsync($buf,0,$toRead).Result
                if ($read -le 0) { break }
                $out.WriteAsync($buf,0,$read).Wait()
                $remaining -= $read
            }
        } else {
            while ($remaining -gt 0) {
                $toRead = [math]::Min($buf.Length, $remaining)
                $read = $fs.Read($buf,0,$toRead)
                if ($read -le 0) { break }
                $out.Write($buf,0,$read)
                $remaining -= $read
            }
        }

        $out.Close()
        Write-Host ("Split Writing chunk {0}/{1} -> {2}" -f $idx, $total, $part)
        $idx++
    }

    $fs.Close()
    Write-Host ("Split complete, total {0} chunks." -f ($idx-1))
}

# ================= 文件合并 =================
function Merge-Parts {
    param([string]$File, [int]$BufSize, [int]$FSBufSize, [int]$Pad)

    $basename = [IO.Path]::GetFileName($File)
    $dir = [IO.Path]::GetDirectoryName($File)
    $outName = [IO.Path]::GetFileNameWithoutExtension($basename)
    $outFile = Join-Path $dir $outName

    if (Test-Path $outFile) { Remove-Item $outFile }

    Write-Host ("Start merging file: {0}" -f $File)

    $buf = New-Object byte[] $BufSize
    $parts = Get-ChildItem -LiteralPath $dir -Filter "$outName.part*" | Sort-Object Name
    $out = New-Object IO.FileStream($outFile,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None,$FSBufSize)
    $idx = 0

    foreach ($p in $parts) {
        $fs = [IO.File]::OpenRead($p.FullName)

        if ($SSD_MODE -eq 1 -and $PSVersionTable.PSVersion.Major -ge 7) {
            while (($read = $fs.ReadAsync($buf,0,$buf.Length).Result) -gt 0) {
                $out.WriteAsync($buf,0,$read).Wait()
            }
        } else {
            while (($read = $fs.Read($buf,0,$buf.Length)) -gt 0) {
                $out.Write($buf,0,$read)
            }
        }

        $fs.Close()
        $idx++
        Write-Host ("Merging chunk {0}: {1}" -f $idx, $p.FullName)
    }

    $out.Close()
    Write-Host ("Merge complete, total {0} chunks -> {1}" -f $idx, $outFile)
}

# ================= 主逻辑 =================
if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "Please drag and drop files onto this script."
    exit
}

$CHUNK_SIZE  = $CHUNK_MB * 1MB
$BUF_SIZE    = $BUF_MB * 1MB
$FS_BUF_SIZE = $FS_BUF_MB * 1MB
$startTime = Get-Date

foreach ($file in $Files) {
    $path     = [IO.Path]::GetFullPath($file)
    $filename = [IO.Path]::GetFileName($file)

    Write-Host "`n=========================="
    Write-Host ("Processing file: {0}" -f $path)
    Write-Host "=========================="

    if ($filename -like "*.part*") {
        Write-Host "Detected .part file, starting merge..."
        Merge-Parts -File $path -BufSize $BUF_SIZE -FSBufSize $FS_BUF_SIZE -Pad $PART_PAD
    } else {
        Write-Host "Detected normal file, starting split..."
        Split-File -File $path -ChunkSize $CHUNK_SIZE -BufSize $BUF_SIZE -FSBufSize $FS_BUF_SIZE -Pad $PART_PAD
    }
}

$elapsed = [int]((Get-Date) - $startTime).TotalSeconds

Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "All files processed!"
Write-Host ""
Write-Host ("Total elapsed time: {0} seconds" -f $elapsed)
Write-Host ""
