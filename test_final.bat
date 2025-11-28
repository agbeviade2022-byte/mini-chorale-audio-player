@echo off
chcp 65001 >nul
echo ========================================
echo Test Final - Version 1.0.3+4
echo Fonctionnalités:
echo   - AudioHandler corrigé
echo   - Fermeture clavier recherche
echo   - Mode hors ligne avec grisage
echo ========================================
echo.

cd /d "%~dp0"

echo 🧹 Nettoyage...
flutter clean
echo.

echo 📦 Dépendances...
flutter pub get
echo.

echo 🚀 Lancement sur émulateur...
echo.
echo 📊 Tests à effectuer:
echo    1. Rechercher un chant puis cliquer en dehors
echo    2. Activer mode avion et voir chants grisés
echo    3. Cliquer sur chant grisé pour voir popup
echo    4. Télécharger un chant et vérifier qu'il reste disponible hors ligne
echo.

start "Flutter Logs" cmd /k "flutter logs"

timeout /t 2 /nobreak >nul

flutter run --release -d emulator-5554

pause
