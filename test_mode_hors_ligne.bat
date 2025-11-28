@echo off
chcp 65001 >nul
echo ========================================
echo Test Mode Hors Ligne - Version 1.0.4+5
echo ========================================
echo.

cd /d "%~dp0"

echo 🔧 Corrections appliquées:
echo    ✅ Utilisation du StreamProvider pour détection temps réel
echo    ✅ Correction de l'API connectivity_plus
echo    ✅ Support de List^<ConnectivityResult^>
echo.

echo 🧹 Nettoyage...
flutter clean
echo.

echo 📦 Dépendances...
flutter pub get
echo.

echo 🚀 Lancement sur émulateur...
echo.
echo ⚠️  IMPORTANT - Tests à effectuer:
echo.
echo 📱 ÉTAPE 1: Vérifier en ligne
echo    1. L'app se lance normalement
echo    2. Tous les chants sont visibles (opacité 100%%)
echo    3. Cliquer sur un chant → Il joue normalement
echo.
echo ✈️  ÉTAPE 2: Activer le mode avion
echo    1. Sur l'émulateur: Paramètres ^> Réseau ^> Désactiver WiFi
echo    2. Retourner dans l'app
echo    3. Les chants NON téléchargés doivent être GRISÉS (40%% opacité)
echo    4. Cliquer sur un chant grisé → Popup "Hors connexion"
echo.
echo 💾 ÉTAPE 3: Télécharger un chant
echo    1. Désactiver le mode avion
echo    2. Télécharger un chant (icône download)
echo    3. Réactiver le mode avion
echo    4. Le chant téléchargé reste NORMAL (100%% opacité)
echo    5. Il est JOUABLE hors ligne
echo.
echo 🔄 ÉTAPE 4: Reconnexion
echo    1. Désactiver le mode avion
echo    2. Tous les chants redeviennent normaux automatiquement
echo.

start "Flutter Logs" cmd /k "flutter logs | findstr /i ""connexion offline download available"""

timeout /t 3 /nobreak >nul

flutter run --release -d emulator-5554

pause
