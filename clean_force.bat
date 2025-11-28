@echo off
chcp 65001 >nul
echo ========================================
echo Nettoyage Forcé - Version 1.0.7+8
echo ========================================
echo.

cd /d "%~dp0"

echo 🛑 Arrêt des processus Flutter/Dart/Java/Gradle/ADB...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM java.exe 2>nul
taskkill /F /IM javaw.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
taskkill /F /IM adb.exe 2>nul
taskkill /F /IM qemu-system-x86_64.exe 2>nul
echo.

echo ⏳ Attente de 5 secondes...
timeout /t 5 /nobreak >nul
echo.

echo 🗑️  Suppression du dossier build...
if exist build (
    rmdir /s /q build 2>nul
    if exist build (
        echo ⚠️  Le dossier build est toujours verrouillé
        echo.
        echo 💡 Solutions:
        echo    1. Fermez VS Code complètement
        echo    2. Fermez Android Studio si ouvert
        echo    3. Relancez ce script
        echo.
        pause
        exit /b 1
    ) else (
        echo ✅ Dossier build supprimé
    )
) else (
    echo ✅ Pas de dossier build à supprimer
)
echo.

echo 🧹 Flutter clean...
flutter clean
echo.

echo 📦 Récupération des dépendances...
flutter pub get
echo.

echo ✅ Nettoyage terminé!
echo.
echo 🚀 Vous pouvez maintenant lancer:
echo    flutter run --release -d emulator-5554
echo.
pause
