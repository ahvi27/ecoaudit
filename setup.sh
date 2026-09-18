#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter create . --platforms=android,ios
flutter pub get

echo "EcoAudit is ready. Add the camera/location permissions documented in README.md, then run: flutter run"
