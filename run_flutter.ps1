# ─────────────────────────────────────────────────────────────────
# Script de lancement Flutter pour émulateur avec peu de stockage
# Usage : .\run_flutter.ps1
# ─────────────────────────────────────────────────────────────────

$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$APK = "build\app\outputs\flutter-apk\app-debug.apk"
$PACKAGE = "com.example.reclamation_attijari"
$ACTIVITY = "$PACKAGE/.MainActivity"

Write-Host "🔨 Build Flutter..." -ForegroundColor Cyan
flutter build apk --debug 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build échouée" -ForegroundColor Red
    exit 1
}
Write-Host "✅ APK construit" -ForegroundColor Green

Write-Host "`n🧹 Nettoyage /data/local/tmp..." -ForegroundColor Cyan
& $ADB shell rm -rf /data/local/tmp/* 2>&1 | Out-Null

Write-Host "📦 Installation APK..." -ForegroundColor Cyan
$result = & $ADB install -r -t $APK 2>&1
if ($result -match "Success") {
    Write-Host "✅ APK installé" -ForegroundColor Green
} else {
    Write-Host "❌ Installation échouée: $result" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔔 Accord permission POST_NOTIFICATIONS..." -ForegroundColor Cyan
& $ADB shell pm grant $PACKAGE android.permission.POST_NOTIFICATIONS 2>&1 | Out-Null
Write-Host "✅ Permission accordée" -ForegroundColor Green

Write-Host "`n🚀 Lancement de l'application..." -ForegroundColor Cyan
& $ADB shell am start -n $ACTIVITY 2>&1

Write-Host "`n📋 Logs FCM en temps réel (Ctrl+C pour stopper)..." -ForegroundColor Yellow
& $ADB logcat -s flutter 2>&1
