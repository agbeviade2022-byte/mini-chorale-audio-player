@echo off
chcp 65001 >nul
echo ========================================
echo Correction withValues -^> withOpacity
echo ========================================
echo.

cd /d "%~dp0"

echo Remplacement dans les fichiers Dart...
echo.

powershell -Command "(Get-Content 'lib\screens\home\home_screen.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\home\home_screen.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\chants\chants_pupitre_list.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\chants\chants_pupitre_list.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\player\full_player.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\player\full_player.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\chants\chants_list.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\chants\chants_list.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\auth\login.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\auth\login.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\widgets\champ_recherche.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\widgets\champ_recherche.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\config\theme.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\config\theme.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\auth\register.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\auth\register.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\widgets\chants_filter.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\widgets\chants_filter.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\player\mini_player.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\player\mini_player.dart' -NoNewline"
powershell -Command "(Get-Content 'lib\screens\splash\splash_screen.dart' -Raw) -replace '\.withValues\(alpha:', '.withOpacity(' | Set-Content 'lib\screens\splash\splash_screen.dart' -NoNewline"

echo.
echo ✅ Remplacement terminé!
echo.
echo Prochaines étapes:
echo   1. flutter clean
echo   2. flutter pub get
echo   3. flutter build apk --release
echo.
pause
