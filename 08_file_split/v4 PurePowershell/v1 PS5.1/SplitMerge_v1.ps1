<#
File Split / Merge Tool (高速版)
拖放文件即可分割或合并
注意: 路径中不能有 "!" "`" "'" """ 等符号...
#>
param(
    [string[]]$Files = $args
)

# ================= 用户设置 =================
$CHUNK_MB = 100      # 每块大小（单位MB）
$BUF_MB   = 32      # 缓冲区大小（单位MB）
$PART_PAD = 3        # 分块编号位数（如 3 表示 part001）
# =============================================

# ==============================
# 子程序：写日志
# ==============================
function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# ==============================
# 子程序：文件分割
# ==============================
function Split-File {
    param(
        [string]$File,
        [long]$ChunkSize,
        [int]$BufSize,
        [int]$Pad
    )
    $logFile = Join-Path (Split-Path $File -Parent) ("{0}.split.log" -f (Split-Path $File -Leaf))
    Write-Log "分割大小: $($ChunkSize/1MB) MB" $logFile
    Write-Log "缓冲区大小: $($BufSize/1MB) MB" $logFile

    $fs = [IO.File]::OpenRead($File)
    $buf = New-Object byte[] $BufSize
    $total = [math]::Ceiling($fs.Length / $ChunkSize)
    $idx = 1
    while ($fs.Position -lt $fs.Length) {
        $suffix = $idx.ToString("D$Pad")
        $part = Join-Path (Split-Path $File -Parent) ("{0}.part{1}" -f (Split-Path $File -Leaf), $suffix)
        $out = [IO.File]::Open($part,[IO.FileMode]::Create,[IO.FileAccess]::Write)
        $remaining = [math]::Min($ChunkSize, $fs.Length - $fs.Position)
        while ($remaining -gt 0) {
            $toRead = [math]::Min($buf.Length, $remaining)
            $read = $fs.Read($buf,0,$toRead)
            if ($read -le 0) { break }
            $out.Write($buf,0,$read)
            $remaining -= $read
        }
        $out.Close()
        Write-Log "正在写入分块 $idx/$total -> $part" $logFile
        $idx++
    }
    $fs.Close()
    Write-Log "完成，共生成 $($idx-1) 个分块。" $logFile
}

# ==============================
# 子程序：文件合并
# ==============================
function Merge-Parts {
    param(
        [string]$File,
        [int]$BufSize,
        [int]$Pad
    )
    $basename = [IO.Path]::GetFileName($File)
    $dir = [IO.Path]::GetDirectoryName($File)
    $outName = [IO.Path]::GetFileNameWithoutExtension($basename)
    $outFile = Join-Path $dir $outName
    $logFile = Join-Path $dir ("{0}.merge.log" -f $outName)
    if (Test-Path $outFile) { Remove-Item $outFile }

    $buf = New-Object byte[] $BufSize
    $parts = Get-ChildItem -LiteralPath $dir -Filter "$outName.part*" | Sort-Object Name
    $out = [IO.File]::Open($outFile,[IO.FileMode]::Create,[IO.FileAccess]::Write)
    $idx = 0
    foreach ($p in $parts) {
        $fs = [IO.File]::OpenRead($p.FullName)
        while (($read=$fs.Read($buf,0,$buf.Length)) -gt 0) {
            $out.Write($buf,0,$read)
        }
        $fs.Close()
        $idx++
        Write-Log "正在合并第 $idx 块: $($p.FullName)" $logFile
    }
    $out.Close()
    Write-Log "合并完成，共 $idx 个分块 -> $outFile" $logFile
}

# ================= 主逻辑 =================
if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "请把文件拖放到此脚本上"    
    Write-Host "等待 5 秒，按任意键跳过..." ; cmd /c "timeout /t 5 >nul"
    exit
}

$CHUNK_SIZE = $CHUNK_MB * 1MB
$BUF_SIZE   = $BUF_MB * 1MB
$startTime = Get-Date

foreach ($file in $Files) {
    $path     = [IO.Path]::GetFullPath($file)
    $filename = [IO.Path]::GetFileName($file)
    Write-Host "`n=========================="
    Write-Host "处理文件: $path"
    Write-Host "=========================="
    if ($filename -like "*.part*") {
        Write-Host "检测到 .part 文件，开始合并..."
        Merge-Parts -File $path -BufSize $BUF_SIZE -Pad $PART_PAD
    } else {
        Write-Host "检测到普通文件，准备分割..."
        Split-File -File $path -ChunkSize $CHUNK_SIZE -BufSize $BUF_SIZE -Pad $PART_PAD
    }
}

$elapsed = [int]((Get-Date) - $startTime).TotalSeconds
Write-Host "`n所有文件处理完成!"
Write-Host "总耗时: $elapsed 秒"
Write-Host "等待 5 秒，按任意键跳过..." ; cmd /c "timeout /t 5 >nul"

