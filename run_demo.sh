#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/app"
command -v flutter >/dev/null || { echo "Flutter SDK not found in PATH."; exit 1; }
if [ ! -d android ]; then flutter create --platforms=android,web .; fi
flutter pub get
flutter run --dart-define=DEMO_MODE=true
