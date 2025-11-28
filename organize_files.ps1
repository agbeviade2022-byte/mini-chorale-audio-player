# Script PowerShell pour organiser les fichiers
# Exécuter avec: powershell -ExecutionPolicy Bypass -File organize_files.ps1

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Organisation des fichiers du projet" -ForegroundColor Cyan
Write-Host "Mini-Chorale Audio Player" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Créer la structure de dossiers
Write-Host "Création de la structure lib..." -ForegroundColor Yellow

$folders = @(
    "lib",
    "lib\config",
    "lib\models",
    "lib\services",
    "lib\providers",
    "lib\widgets",
    "lib\screens",
    "lib\screens\splash",
    "lib\screens\onboarding",
    "lib\screens\auth",
    "lib\screens\home",
    "lib\screens\chants",
    "lib\screens\player",
    "lib\screens\admin",
    "assets",
    "assets\images",
    "assets\icons"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  ✓ Créé: $folder" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Déplacement des fichiers..." -ForegroundColor Yellow

# Fonction pour déplacer un fichier
function Move-FileIfExists {
    param($source, $destination)
    if (Test-Path $source) {
        Move-Item -Path $source -Destination $destination -Force
        Write-Host "  ✓ $source → $destination" -ForegroundColor Green
        return $true
    }
    return $false
}

# Déplacer main.dart
Move-FileIfExists "main.dart" "lib\main.dart"

# Déplacer config
Move-FileIfExists "config_theme.dart" "lib\config\theme.dart"

# Déplacer models
Move-FileIfExists "model_chant.dart" "lib\models\chant.dart"
Move-FileIfExists "model_user.dart" "lib\models\user.dart"
Move-FileIfExists "model_category.dart" "lib\models\category.dart"
Move-FileIfExists "model_subscription.dart" "lib\models\subscription.dart"

# Déplacer services
Move-FileIfExists "service_auth.dart" "lib\services\supabase_auth_service.dart"
Move-FileIfExists "service_chants.dart" "lib\services\supabase_chants_service.dart"
Move-FileIfExists "service_storage.dart" "lib\services\supabase_storage_service.dart"
Move-FileIfExists "service_audio_player.dart" "lib\services\audio_player_service.dart"

# Déplacer providers
Move-FileIfExists "provider_auth.dart" "lib\providers\auth_provider.dart"
Move-FileIfExists "provider_chants.dart" "lib\providers\chants_provider.dart"
Move-FileIfExists "provider_audio.dart" "lib\providers\audio_provider.dart"

# Déplacer widgets
Move-FileIfExists "widget_custom_button.dart" "lib\widgets\custom_button.dart"
Move-FileIfExists "widget_champ_recherche.dart" "lib\widgets\champ_recherche.dart"
Move-FileIfExists "widget_audio_wave.dart" "lib\widgets\audio_wave.dart"

# Déplacer screens
Move-FileIfExists "screen_splash.dart" "lib\screens\splash\splash_screen.dart"
Move-FileIfExists "screen_onboarding.dart" "lib\screens\onboarding\onboarding_screen.dart"
Move-FileIfExists "screen_login.dart" "lib\screens\auth\login.dart"
Move-FileIfExists "screen_register.dart" "lib\screens\auth\register.dart"
Move-FileIfExists "screen_home.dart" "lib\screens\home\home_screen.dart"
Move-FileIfExists "screen_chants_list.dart" "lib\screens\chants\chants_list.dart"
Move-FileIfExists "screen_chant_details.dart" "lib\screens\chants\chant_details.dart"
Move-FileIfExists "screen_mini_player.dart" "lib\screens\player\mini_player.dart"
Move-FileIfExists "screen_full_player.dart" "lib\screens\player\full_player.dart"
Move-FileIfExists "screen_add_chant.dart" "lib\screens\admin\add_chant.dart"
Move-FileIfExists "screen_add_category.dart" "lib\screens\admin\add_category.dart"

# Supprimer fichiers temporaires
Write-Host ""
Write-Host "Nettoyage..." -ForegroundColor Yellow
if (Test-Path "main_temp.dart") {
    Remove-Item "main_temp.dart" -Force
    Write-Host "  ✓ Supprimé: main_temp.dart" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Organisation terminée avec succès!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Exécuter: flutter pub get" -ForegroundColor White
Write-Host "2. Configurer Supabase (voir README.md)" -ForegroundColor White
Write-Host "3. Lancer: flutter run" -ForegroundColor White
Write-Host ""
