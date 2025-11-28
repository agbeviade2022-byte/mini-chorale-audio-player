@echo off
chcp 65001 >nul
echo ========================================
echo Installation Mini Chorale Audio Player
echo Version 1.0.1+2
echo ========================================
echo.

cd /d "%~dp0"

echo 📱 Vérification de la connexion ADB...
adb devices
echo.

echo 🗑️  Désinstallation de l'ancienne version...
adb uninstall com.example.mini_chorale_audio_player
echo.

echo 📦 Installation de la nouvelle version...
adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
echo.

echo ✅ Installation terminée!
echo.
echo 🚀 Lancement de l'application...
adb shell am start -n com.example.mini_chorale_audio_player/.MainActivity
echo.

echo 📊 Pour voir les logs en temps réel:
echo    adb logcat -s flutter
echo.
pause
