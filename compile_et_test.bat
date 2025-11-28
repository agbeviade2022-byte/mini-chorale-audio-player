@echo off
chcp 65001 >nul
echo ========================================
echo Compilation et Test - Version 1.0.4+5
echo ========================================
echo.

cd /d "%~dp0"

echo 🛑 Arrêt des processus...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM java.exe 2>nul
echo.

echo ⏳ Attente...
timeout /t 2 /nobreak >nul
echo.

echo 🗑️  Suppression build...
if exist build (
    rmdir /s /q build 2>nul
)
echo.

echo 🧹 Flutter clean...
flutter clean
echo.

echo 📦 Dépendances...
flutter pub get
echo.

echo 🔨 Compilation en cours...
echo.
echo 📊 Surveillez les logs pour:
echo    🌐 Changement de connexion détecté
echo    ✅ Chant disponible/non disponible
echo.

start "Flutter Logs - Mode Hors Ligne" cmd /k "flutter logs | findstr /i ""connexion available offline download"""

timeout /t 3 /nobreak >nul

echo 🚀 Lancement sur émulateur...
flutter run --release -d emulator-5554

pause
