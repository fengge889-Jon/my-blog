# Fix git locks and push
$BlogRoot = $PSScriptRoot
Set-Location $BlogRoot

# Remove lock files
$locks = @(
    "$BlogRoot\.git\index.lock",
    "$BlogRoot\.git\refs\remotes\origin\main.lock",
    "$BlogRoot\.git\refs\heads\main.lock"
)
foreach ($lock in $locks) {
    if (Test-Path $lock) {
        Remove-Item $lock -Force
        Write-Host "Removed: $lock" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Git status:" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git add .
git commit -m "post: update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Done! https://my-blog-1mc.pages.dev" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Push failed. Check the error above." -ForegroundColor Red
}
