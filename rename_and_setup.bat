@echo off
echo ============================================
echo Renommage du projet et configuration
echo ============================================
echo.

cd ..
echo Renommage du dossier...
ren "App Music Flutter" "mini_chorale_audio_player"

cd mini_chorale_audio_player
echo.
echo Creation des plateformes Windows et Web...
flutter create --platforms=windows,web .

echo.
echo Installation des dependances...
flutter pub get

echo.
echo ============================================
echo Configuration terminee!
echo ============================================
echo.
echo Vous pouvez maintenant lancer:
echo   flutter run -d windows
echo ou
echo   flutter run -d chrome
echo.
pause
