@echo off
chcp 65001 >nul
echo ========================================
echo Installation sur Téléphone Réel
echo Version 1.0.2+3 - ARM64
echo ========================================
echo.

cd /d "%~dp0"

echo 📱 Vérification de la connexion...
adb devices
echo.

echo ⚠️  Assurez-vous que:
echo    1. Le téléphone est connecté en USB
echo    2. Le débogage USB est activé
echo    3. Vous avez autorisé le débogage sur le téléphone
echo.
pause

echo.
echo 🗑️  Désinstallation de l'ancienne version...
adb uninstall com.example.mini_chorale_audio_player
echo.

echo 📦 Installation de la nouvelle version (ARM64)...
adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
echo.

if errorlevel 1 (
    echo ❌ Erreur lors de l'installation
    echo.
    echo 💡 Solutions possibles:
    echo    1. Vérifier que le téléphone est bien connecté
    echo    2. Activer le débogage USB dans les options développeur
    echo    3. Autoriser l'installation depuis cet ordinateur
    echo.
    pause
    exit /b 1
)

echo ✅ Installation réussie!
echo.
echo 🚀 Lancement de l'application...
adb shell am start -n com.example.mini_chorale_audio_player/.MainActivity
echo.

echo 📊 Pour voir les logs en temps réel:
echo    adb logcat -s flutter
echo.
echo ✅ L'application est maintenant installée sur votre téléphone!
echo.
pause
