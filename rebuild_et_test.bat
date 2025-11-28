@echo off
chcp 65001 >nul
echo ========================================
echo Rebuild après correction AudioHandler
echo Version 1.0.2+3
echo ========================================
echo.

cd /d "%~dp0"

echo 🧹 Nettoyage complet...
flutter clean
echo.

echo 📦 Récupération des dépendances...
flutter pub get
echo.

echo 🔨 Compilation et lancement sur émulateur...
echo.
echo 📊 Surveillez les logs pour voir:
echo    ✅ AudioService initialisé avec succès
echo    🎵 Chargement audio: ...
echo    ✅ Audio chargé avec succès
echo.

start "Flutter Logs" cmd /k "flutter logs"

timeout /t 2 /nobreak >nul

flutter run --release -d emulator-5554

pause
