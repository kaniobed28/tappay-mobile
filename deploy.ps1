# TapPay web deploy — build Flutter web, restore SPA rewrite, deploy to Vercel prod.
# Usage:  ./deploy.ps1     (run from the mobile/ folder)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "==> flutter build web --release" -ForegroundColor Cyan
flutter build web --release

Write-Host "==> restoring vercel.json (Flutter wipes build/web on each build)" -ForegroundColor Cyan
Copy-Item "$root\web-vercel.json" "$root\build\web\vercel.json" -Force

Write-Host "==> deploying build/web to Vercel (production)" -ForegroundColor Cyan
Push-Location "$root\build\web"
try { vercel deploy --prod --yes --name tappay }
finally { Pop-Location }

Write-Host "Done -> https://tappay-nine.vercel.app" -ForegroundColor Green
