# Hexo Blog Publisher
# Usage: double-click "publish.bat" to run

$BlogRoot = $PSScriptRoot
$PostsDir = "$BlogRoot\source\_posts"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Hexo Blog Publisher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select an option:" -ForegroundColor Yellow
Write-Host "  [1] Create new post (edit later)"
Write-Host "  [2] Publish all posts to GitHub"
Write-Host "  [3] Create new post + open in WPS"
Write-Host ""
$mode = Read-Host "Enter number"

if ($mode -eq "1" -or $mode -eq "3") {
    Write-Host ""
    $title = Read-Host "Post title"
    if ([string]::IsNullOrWhiteSpace($title)) {
        Write-Host "ERROR: Title cannot be empty" -ForegroundColor Red
        exit 1
    }

    $slug = $title -replace '[\\/:*?"<>|]', '' -replace '\s+', '-'
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fileName = "$slug.md"
    $filePath = "$PostsDir\$fileName"

    $lines = @(
        "---",
        "title: $title",
        "date: $date",
        "tags:",
        "categories:",
        "---",
        "",
        ""
    )
    [System.IO.File]::WriteAllLines($filePath, $lines, [System.Text.Encoding]::UTF8)

    Write-Host ""
    Write-Host "Post created: $filePath" -ForegroundColor Green

    if ($mode -eq "3") {
        Write-Host "Opening WPS..." -ForegroundColor Cyan
        $wpsPaths = @(
            "$env:ProgramFiles\Kingsoft\WPS Office\office6\wps.exe",
            "${env:ProgramFiles(x86)}\Kingsoft\WPS Office\office6\wps.exe",
            "$env:LOCALAPPDATA\Kingsoft\WPS Office\office6\wps.exe"
        )
        $wpsExe = $wpsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($wpsExe) {
            Start-Process $wpsExe -ArgumentList "`"$filePath`""
        } else {
            Start-Process $filePath
        }
        Write-Host ""
        Write-Host "Tip: After writing, run this script again and choose [2] to publish." -ForegroundColor Yellow
    }
    exit 0
}

if ($mode -eq "2") {
    Write-Host ""
    Write-Host "Posts in _posts:" -ForegroundColor Cyan
    $posts = Get-ChildItem $PostsDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
    $i = 1
    foreach ($p in $posts) {
        Write-Host ("  [{0}] {1}  ({2})" -f $i, $p.Name, $p.LastWriteTime.ToString("MM-dd HH:mm"))
        $i++
    }

    Write-Host ""
    $confirm = Read-Host "Publish all to GitHub? (y/n)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Gray
        exit 0
    }

    Set-Location $BlogRoot

    Write-Host ""
    Write-Host "[1/3] Cleaning old build..." -ForegroundColor Cyan
    npx hexo clean 2>&1 | Out-Null

    Write-Host "[2/3] Generating static files..." -ForegroundColor Cyan
    $buildOutput = npx hexo generate 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed:" -ForegroundColor Red
        Write-Host $buildOutput
        exit 1
    }
    Write-Host "Build OK" -ForegroundColor Green

    Write-Host "[3/3] Pushing to GitHub..." -ForegroundColor Cyan
    git add .
    $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "post: update $dateStr"
    git push origin main 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Published! Cloudflare Pages is building, will be live in ~1-2 min." -ForegroundColor Green
        Write-Host "Blog: https://my-blog-1mc.pages.dev" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: Push failed. Check your Git config or network." -ForegroundColor Red
    }
    exit 0
}

Write-Host "Invalid option." -ForegroundColor Red
