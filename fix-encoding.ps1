# Fix file encoding to UTF-8 without BOM
$BlogRoot = $PSScriptRoot
Set-Location $BlogRoot

$posts = Get-ChildItem "source/_posts" -Filter "*.md"

foreach ($post in $posts) {
    $content = Get-Content $post.FullName -Raw -Encoding UTF8
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($post.FullName, $content, $utf8NoBom)
    Write-Host "Fixed: $($post.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Committing..." -ForegroundColor Cyan
git add .
git commit -m "fix: UTF-8 encoding"
git push origin main 2>&1

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
