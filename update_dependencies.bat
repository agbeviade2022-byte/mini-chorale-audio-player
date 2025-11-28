@echo off
chcp 65001 >nul
echo ========================================
echo Mise à jour des dépendances - v1.1.5+16
echo ========================================
echo.

cd /d "%~dp0"

echo 🛑 Arrêt des processus Flutter...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
echo.

echo ⏳ Attente de 2 secondes...
timeout /t 2 /nobreak >nul
echo.

echo 🗑️  Suppression du cache pub...
if exist "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-16.3.3" (
    rmdir /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-16.3.3" 2>nul
    echo ✅ Cache flutter_local_notifications 16.3.3 supprimé
) else (
    echo ℹ️  Pas de cache 16.3.3 à supprimer
)
echo.

echo 🗑️  Suppression du dossier build...
if exist build (
    rmdir /s /q build 2>nul
    if exist build (
        echo ⚠️  Le dossier build est toujours verrouillé
        echo 💡 Fermez VS Code et relancez ce script
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

echo ✅ Mise à jour terminée!
echo.
echo 📋 Version flutter_local_notifications: 17.0.0
echo.
echo 🚀 Vous pouvez maintenant lancer:
echo    flutter run --release -d emulator-5554
echo.
pause
