@echo off
echo ============================================
echo Organisation des fichiers du projet
echo Mini-Chorale Audio Player
echo ============================================
echo.

REM Créer la structure de dossiers
echo Creation de la structure lib...
if not exist "lib" mkdir lib
if not exist "lib\config" mkdir lib\config
if not exist "lib\models" mkdir lib\models
if not exist "lib\services" mkdir lib\services
if not exist "lib\providers" mkdir lib\providers
if not exist "lib\widgets" mkdir lib\widgets
if not exist "lib\screens" mkdir lib\screens
if not exist "lib\screens\splash" mkdir lib\screens\splash
if not exist "lib\screens\onboarding" mkdir lib\screens\onboarding
if not exist "lib\screens\auth" mkdir lib\screens\auth
if not exist "lib\screens\home" mkdir lib\screens\home
if not exist "lib\screens\chants" mkdir lib\screens\chants
if not exist "lib\screens\player" mkdir lib\screens\player
if not exist "lib\screens\admin" mkdir lib\screens\admin

if not exist "assets" mkdir assets
if not exist "assets\images" mkdir assets\images
if not exist "assets\icons" mkdir assets\icons

echo Structure creee avec succes!
echo.

REM Déplacer main.dart si nécessaire
echo Deplacement de main.dart...
if exist "main.dart" (
    move /Y "main.dart" "lib\main.dart" >nul 2>&1
    echo main.dart deplace dans lib\
) else (
    echo main.dart deja en place ou introuvable
)

REM Déplacer config
echo Deplacement des fichiers config...
if exist "config_theme.dart" (
    move /Y "config_theme.dart" "lib\config\theme.dart" >nul 2>&1
    echo theme.dart deplace
)

REM Déplacer models
echo Deplacement des modeles...
if exist "model_chant.dart" move /Y "model_chant.dart" "lib\models\chant.dart" >nul 2>&1
if exist "model_user.dart" move /Y "model_user.dart" "lib\models\user.dart" >nul 2>&1
if exist "model_category.dart" move /Y "model_category.dart" "lib\models\category.dart" >nul 2>&1
if exist "model_subscription.dart" move /Y "model_subscription.dart" "lib\models\subscription.dart" >nul 2>&1
echo Modeles deplaces

REM Déplacer services
echo Deplacement des services...
if exist "service_auth.dart" move /Y "service_auth.dart" "lib\services\supabase_auth_service.dart" >nul 2>&1
if exist "service_chants.dart" move /Y "service_chants.dart" "lib\services\supabase_chants_service.dart" >nul 2>&1
if exist "service_storage.dart" move /Y "service_storage.dart" "lib\services\supabase_storage_service.dart" >nul 2>&1
if exist "service_audio_player.dart" move /Y "service_audio_player.dart" "lib\services\audio_player_service.dart" >nul 2>&1
echo Services deplaces

REM Déplacer providers
echo Deplacement des providers...
if exist "provider_auth.dart" move /Y "provider_auth.dart" "lib\providers\auth_provider.dart" >nul 2>&1
if exist "provider_chants.dart" move /Y "provider_chants.dart" "lib\providers\chants_provider.dart" >nul 2>&1
if exist "provider_audio.dart" move /Y "provider_audio.dart" "lib\providers\audio_provider.dart" >nul 2>&1
echo Providers deplaces

REM Déplacer widgets
echo Deplacement des widgets...
if exist "widget_custom_button.dart" move /Y "widget_custom_button.dart" "lib\widgets\custom_button.dart" >nul 2>&1
if exist "widget_champ_recherche.dart" move /Y "widget_champ_recherche.dart" "lib\widgets\champ_recherche.dart" >nul 2>&1
if exist "widget_audio_wave.dart" move /Y "widget_audio_wave.dart" "lib\widgets\audio_wave.dart" >nul 2>&1
echo Widgets deplaces

REM Déplacer screens
echo Deplacement des ecrans...
if exist "screen_splash.dart" move /Y "screen_splash.dart" "lib\screens\splash\splash_screen.dart" >nul 2>&1
if exist "screen_onboarding.dart" move /Y "screen_onboarding.dart" "lib\screens\onboarding\onboarding_screen.dart" >nul 2>&1
if exist "screen_login.dart" move /Y "screen_login.dart" "lib\screens\auth\login.dart" >nul 2>&1
if exist "screen_register.dart" move /Y "screen_register.dart" "lib\screens\auth\register.dart" >nul 2>&1
if exist "screen_home.dart" move /Y "screen_home.dart" "lib\screens\home\home_screen.dart" >nul 2>&1
if exist "screen_chants_list.dart" move /Y "screen_chants_list.dart" "lib\screens\chants\chants_list.dart" >nul 2>&1
if exist "screen_chant_details.dart" move /Y "screen_chant_details.dart" "lib\screens\chants\chant_details.dart" >nul 2>&1
if exist "screen_mini_player.dart" move /Y "screen_mini_player.dart" "lib\screens\player\mini_player.dart" >nul 2>&1
if exist "screen_full_player.dart" move /Y "screen_full_player.dart" "lib\screens\player\full_player.dart" >nul 2>&1
if exist "screen_add_chant.dart" move /Y "screen_add_chant.dart" "lib\screens\admin\add_chant.dart" >nul 2>&1
if exist "screen_add_category.dart" move /Y "screen_add_category.dart" "lib\screens\admin\add_category.dart" >nul 2>&1
echo Ecrans deplaces

REM Supprimer les fichiers temporaires
echo.
echo Nettoyage des fichiers temporaires...
if exist "main_temp.dart" del "main_temp.dart" >nul 2>&1

echo.
echo ============================================
echo Organisation terminee avec succes!
echo ============================================
echo.
echo Prochaines etapes:
echo 1. Ouvrir le projet dans votre IDE
echo 2. Executer: flutter pub get
echo 3. Configurer Supabase (voir README.md)
echo 4. Lancer: flutter run
echo.
pause
