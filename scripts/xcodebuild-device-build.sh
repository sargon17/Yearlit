#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"

if [[ -n "${DESTINATION:-}" ]]; then
  destination="${DESTINATION}"
else
  destination="generic/platform=iOS"
  echo "Using generic iOS device build."
fi

xcodebuild build \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -destination "${destination}" \
  -derivedDataPath "${DERIVED_DATA_PATH}"
