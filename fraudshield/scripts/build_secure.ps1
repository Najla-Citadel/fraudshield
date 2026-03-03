# Secure Build Script for FraudShield
# Generates an obfuscated APK with symbol files for debugging

Write-Host "🚀 Starting secure production build..." -ForegroundColor Cyan

# Ensure build directory exists for symbols
New-Item -ItemType Directory -Force -Path "build/app/outputs/symbols" | Out-Null

# Run Flutter build with obfuscation flags
# --obfuscate: hides function and class names
# --split-debug-info: extracts symbol mapping so you can still read stack traces
# --release: ensures production optimizations
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build Complete!" -ForegroundColor Green
    Write-Host "📍 App Bundle: build/app/outputs/bundle/release/app-release.aab"
    Write-Host "📍 Symbols: build/app/outputs/symbols"
    Write-Host "`n⚠️ GOOGLE PLAY CONSOLE: Upload the .aab file and also the debug symbols for better crash reporting." -ForegroundColor Yellow
}
else {
    Write-Host "`n❌ Build Failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}
