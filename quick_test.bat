@echo off
chcp 65001 >nul
echo ========================================
echo Test Rapide - Version 1.0.7+8
echo ========================================
echo.

cd /d "%~dp0"

echo 🛑 Arrêt des processus...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
echo.

echo ⏳ Attente...
timeout /t 2 /nobreak >nul
echo.

echo 📦 Mise à jour des dépendances...
flutter pub get
echo.

echo 🚀 Lancement de l'application...
echo.
echo ⚠️  TESTS À EFFECTUER:
echo.
echo 📱 TEST PERSISTANCE:
echo    1. Lancer l'app EN LIGNE
echo    2. Activer mode avion
echo    3. ✅ Chants grisés
echo    4. FERMER l'app complètement (swipe up)
echo    5. Rouvrir l'app
echo    6. ✅ Chants DÉJÀ grisés dès l'ouverture
echo.
echo 📊 Logs à surveiller:
echo    💾 État en cache: false
echo    🌐 Changement de connexion détecté
echo    💾 État de connexion sauvegardé
echo.

start "Flutter Logs" cmd /k "flutter logs | findstr /i ""cache connexion available offline"""

timeout /t 2 /nobreak >nul

flutter run --release -d emulator-5554

pause
