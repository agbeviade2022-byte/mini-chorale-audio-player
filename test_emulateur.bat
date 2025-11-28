@echo off
chcp 65001 >nul
echo ========================================
echo Test sur Émulateur Android
echo Version 1.0.1+2
echo ========================================
echo.

cd /d "%~dp0"

echo 📱 Appareils connectés:
flutter devices
echo.

echo 🧹 Nettoyage...
flutter clean
echo.

echo 📦 Récupération des dépendances...
flutter pub get
echo.

echo 🔨 Compilation et lancement en mode release...
echo.
echo ⚠️  L'app va se lancer sur l'émulateur
echo    Surveillez les logs pour identifier les problèmes
echo.

start "Flutter Logs" cmd /k "flutter logs"

timeout /t 3 /nobreak >nul

flutter run --release -d emulator-5554

pause
