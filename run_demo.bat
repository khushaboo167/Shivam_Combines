@echo off
setlocal
cd /d "%~dp0app"
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK was not found in PATH.
  echo Install Flutter, reopen this window, then run this file again.
  pause
  exit /b 1
)
if not exist android (
  echo Creating Android/Web platform files...
  flutter create --platforms=android,web .
  if errorlevel 1 exit /b 1
)
call flutter pub get
if errorlevel 1 exit /b 1
flutter run --dart-define=DEMO_MODE=true
