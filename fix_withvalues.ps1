# Script PowerShell pour remplacer withValues par withOpacity
# Correction de l'API Flutter incompatible

Write-Host "🔧 Correction de l'API withValues → withOpacity" -ForegroundColor Cyan
Write-Host ""

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$totalFiles = 0
$totalReplacements = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Remplacer withValues(alpha: X) par withOpacity(X)
    $content = $content -replace '\.withValues\(alpha:\s*([0-9.]+)\)', '.withOpacity($1)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $replacements = ([regex]::Matches($originalContent, '\.withValues\(alpha:')).Count
        $totalReplacements += $replacements
        $totalFiles++
        Write-Host "✅ $($file.Name) - $replacements remplacement(s)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "📊 Résumé:" -ForegroundColor Yellow
Write-Host "   Fichiers modifiés: $totalFiles" -ForegroundColor White
Write-Host "   Total remplacements: $totalReplacements" -ForegroundColor White
Write-Host ""
Write-Host "✅ Correction terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "   1. flutter clean" -ForegroundColor White
Write-Host "   2. flutter pub get" -ForegroundColor White
Write-Host "   3. flutter build apk --release" -ForegroundColor White
