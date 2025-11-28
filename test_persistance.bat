@echo off
chcp 65001 >nul
echo ========================================
echo Test Persistance - Version 1.0.7+8
echo ========================================
echo.

cd /d "%~dp0"

echo 🔧 Nouvelle fonctionnalité:
echo    ✅ État de connexion sauvegardé dans le cache
echo    ✅ Chants grisés dès l'ouverture si hors ligne
echo    ✅ Persistance après fermeture complète
echo.

echo 🧹 Nettoyage...
call clean_force.bat
echo.

echo 🚀 Lancement...
echo.
echo ⚠️  IMPORTANT - Tests à effectuer:
echo.
echo 📱 TEST 1: Persistance après fermeture
echo    1. Lancer l'app EN LIGNE
echo    2. Tous les chants normaux
echo    3. Activer le mode avion
echo    4. ✅ Chants grisés
echo    5. FERMER l'app complètement (swipe up)
echo    6. Rouvrir l'app
echo    7. ✅ Chants DÉJÀ grisés dès l'ouverture
echo    8. Dans les logs: "💾 État en cache: false"
echo.
echo 📱 TEST 2: Retour en ligne
echo    1. En mode avion, chants grisés
echo    2. FERMER l'app
echo    3. Désactiver le mode avion
echo    4. Rouvrir l'app
echo    5. ✅ Chants normaux dès l'ouverture
echo    6. Dans les logs: "💾 État en cache: true"
echo.
echo 📱 TEST 3: Premier lancement
echo    1. Désinstaller l'app
echo    2. Activer le mode avion
echo    3. Installer et lancer l'app
echo    4. ✅ Par défaut, chants normaux (cache vide = en ligne)
echo    5. Après 2-3 secondes, chants deviennent grisés
echo.

start "Flutter Logs - Persistance" cmd /k "flutter logs | findstr /i ""cache connexion available offline"""

timeout /t 3 /nobreak >nul

flutter run --release -d emulator-5554

pause
