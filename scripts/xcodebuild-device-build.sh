#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"
COMPILER_INDEX_STORE_ENABLE="${COMPILER_INDEX_STORE_ENABLE:-NO}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
ENABLE_PREVIEWS="${ENABLE_PREVIEWS:-NO}"

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
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -parallelizeTargets \
  -jobs "${JOBS}" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  COMPILER_INDEX_STORE_ENABLE="${COMPILER_INDEX_STORE_ENABLE}" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED}" \
  ENABLE_PREVIEWS="${ENABLE_PREVIEWS}"
