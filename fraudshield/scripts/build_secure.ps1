# Secure Build Script for FraudShield
# Generates an obfuscated APK with symbol files for debugging

Write-Host "🚀 Starting secure production build..." -ForegroundColor Cyan

# Ensure build directory exists for symbols
New-Item -ItemType Directory -Force -Path "build/app/outputs/symbols" | Out-Null

# Check for production configuration file
$configPath = "build_config.json"
$configParams = ""

if (Test-Path $configPath) {
    Write-Host "✅ Production config found: $configPath" -ForegroundColor Green
    $configParams = "--dart-define-from-file=$configPath"
}
else {
    Write-Warning "⚠️ $configPath not found. Build will use default development values."
    Write-Warning "   To build for production, create $configPath based on build_config.json.example"
}

# Run Flutter build with obfuscation flags and production config
# --obfuscate: hides function and class names
# --split-debug-info: extracts symbol mapping so you can still read stack traces
# --release: ensures production optimizations
# --dart-define-from-file: loads production secrets from an external JSON
Invoke-Expression "flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols $configParams"

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
