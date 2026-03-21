# Hexo Blog Publisher (Fast Mode)
# Only pushes the public folder (generated HTML), not source markdown files
# Usage: double-click "publish.bat"

$BlogRoot = $PSScriptRoot
$PostsDir = "$BlogRoot\source\_posts"
$PublicDir = "$BlogRoot\public"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Hexo Blog Publisher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select an option:" -ForegroundColor Yellow
Write-Host "  [1] Create new post + open in VS Code"
Write-Host "  [2] Publish (generate + push public folder only)"
Write-Host ""
$mode = Read-Host "Enter number"

if ($mode -eq "1") {
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
    Write-Host "Opening VS Code..." -ForegroundColor Cyan
    code $filePath
    Write-Host ""
    Write-Host "Save (Ctrl+S), close, then run and choose [2] to publish." -ForegroundColor Yellow
    exit 0
}

if ($mode -eq "2") {
    Set-Location $BlogRoot

    Write-Host ""
    Write-Host "[1/3] Generating static files..." -ForegroundColor Cyan
    npx hexo generate 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "      Done" -ForegroundColor Green

    Write-Host ""
    Write-Host "[2/3] Committing public folder..." -ForegroundColor Cyan
    Set-Location $PublicDir

    # Ensure public folder has its own git repo with correct remote
    if (-not (Test-Path ".git")) {
        git init
        git remote add origin https://github.com/fengge889-Jon/my-blog.git
        git checkout -b main
    }

    git add .
    $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "deploy: $dateStr"

    Write-Host ""
    Write-Host "[3/3] Pushing..." -ForegroundColor Cyan
    git push origin main 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Published! https://my-blog-1mc.pages.dev" -ForegroundColor Green
    } else {
        Write-Host "Push failed." -ForegroundColor Red
    }
    exit 0
}

Write-Host "Invalid option." -ForegroundColor Red
