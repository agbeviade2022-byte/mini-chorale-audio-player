@echo off
chcp 65001 >nul
echo ========================================
echo Test Fermeture Clavier Recherche
echo Version 1.0.2+3
echo ========================================
echo.

cd /d "%~dp0"

echo 🔄 Hot reload de l'application...
echo.
echo ✅ Modification appliquée:
echo    - Cliquer dans la barre de recherche
echo    - Cliquer en dehors
echo    - Le clavier devrait se fermer automatiquement
echo.

flutter run --release -d emulator-5554

pause
