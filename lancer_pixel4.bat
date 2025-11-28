@echo off
chcp 65001 >nul
echo ========================================
echo Lancement sur Pixel 4 API 36
echo Version 1.0.1+2
echo ========================================
echo.

cd /d "%~dp0"

echo ⏳ Attente du démarrage de l'émulateur Pixel 4...
echo    (Cela peut prendre 30-60 secondes)
echo.

:wait_loop
flutter devices | findstr "emulator" >nul
if errorlevel 1 (
    timeout /t 5 /nobreak >nul
    goto wait_loop
)

echo ✅ Émulateur détecté!
echo.

echo 📱 Appareils connectés:
flutter devices
echo.

echo 🧹 Nettoyage du projet...
flutter clean
echo.

echo 📦 Récupération des dépendances...
flutter pub get
echo.

echo 🚀 Lancement de l'application en mode release...
echo.
echo 📊 Une fenêtre de logs va s'ouvrir
echo    Surveillez les messages pour identifier les problèmes
echo.

start "Flutter Logs - Pixel 4" cmd /k "flutter logs"

timeout /t 2 /nobreak >nul

flutter run --release

pause
