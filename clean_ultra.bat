@echo off
chcp 65001 >nul
echo ========================================
echo Nettoyage ULTRA - Version 1.0.7+8
echo ========================================
echo.
echo ⚠️  Ce script va fermer VS Code et tous les processus!
echo.
pause

cd /d "%~dp0"

echo.
echo 🛑 Fermeture de VS Code...
taskkill /F /IM Code.exe 2>nul
echo.

echo 🛑 Arrêt de TOUS les processus Flutter/Android...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM java.exe 2>nul
taskkill /F /IM javaw.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
taskkill /F /IM adb.exe 2>nul
taskkill /F /IM qemu-system-x86_64.exe 2>nul
taskkill /F /IM studio64.exe 2>nul
echo.

echo ⏳ Attente de 10 secondes pour libération des fichiers...
timeout /t 10 /nobreak >nul
echo.

echo 🗑️  Suppression du dossier build...
if exist build (
    echo Tentative 1...
    rmdir /s /q build 2>nul
    timeout /t 2 /nobreak >nul
    
    if exist build (
        echo Tentative 2 (avec force)...
        rd /s /q build 2>nul
        timeout /t 2 /nobreak >nul
    )
    
    if exist build (
        echo.
        echo ⚠️  Le dossier build est toujours verrouillé
        echo.
        echo 💡 Solution manuelle:
        echo    1. Ouvrez le Gestionnaire des tâches (Ctrl+Shift+Esc)
        echo    2. Onglet "Détails"
        echo    3. Cherchez et terminez: java.exe, javaw.exe, gradle.exe
        echo    4. Supprimez manuellement le dossier "build"
        echo    5. Relancez ce script
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

echo ✅ Nettoyage ULTRA terminé!
echo.
echo 🚀 Vous pouvez maintenant lancer:
echo    quick_test.bat
echo    OU
echo    flutter run --release -d emulator-5554
echo.
pause
