# Hexo Blog Publisher (UTF-8 without BOM)
# Usage: double-click "publish.bat" to run

$BlogRoot = $PSScriptRoot
$PostsDir = "$BlogRoot\source\_posts"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

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
Write-Host "  [3] Create new post + open in VS Code"
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

    # Use UTF-8 without BOM
    $content = @"
---
title: $title
date: $date
tags:
categories:
---

"@
    [System.IO.File]::WriteAllText($filePath, $content, $Utf8NoBom)

    Write-Host ""
    Write-Host "Post created: $filePath" -ForegroundColor Green

    if ($mode -eq "3") {
        Write-Host "Opening VS Code..." -ForegroundColor Cyan
        code $filePath
        Write-Host ""
        Write-Host "Tip: After writing, save (Ctrl+S) and close VS Code," -ForegroundColor Yellow
        Write-Host "      then run this script again and choose [2] to publish." -ForegroundColor Yellow
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

    # Fix encoding for all posts before publishing
    Write-Host ""
    Write-Host "[0/4] Fixing file encoding (UTF-8 without BOM)..." -ForegroundColor Cyan
    foreach ($p in $posts) {
        $content = Get-Content $p.FullName -Raw -Encoding UTF8
        [System.IO.File]::WriteAllText($p.FullName, $content, $Utf8NoBom)
    }
    Write-Host "      Encoding fixed." -ForegroundColor Green

    Write-Host ""
    Write-Host "[1/4] Cleaning old build..." -ForegroundColor Cyan
    npx hexo clean 2>&1 | Out-Null

    Write-Host "[2/4] Generating static files..." -ForegroundColor Cyan
    $buildOutput = npx hexo generate 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed:" -ForegroundColor Red
        Write-Host $buildOutput
        exit 1
    }
    Write-Host "      Build OK" -ForegroundColor Green

    Write-Host "[3/4] Pushing to GitHub..." -ForegroundColor Cyan
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
