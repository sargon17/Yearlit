#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"

if [[ -n "${DESTINATION:-}" ]]; then
  destination="${DESTINATION}"
else
  destinations="$(xcodebuild -showdestinations -project "${PROJECT}" -scheme "${SCHEME}" 2>/dev/null || true)"
  if grep -q 'error:' <<< "${destinations}"; then
    destination="generic/platform=iOS"
    echo "Connected iOS device destination is unavailable. Using generic iOS device build."
  else
    device_id="$(awk -F '[{},]' '/platform:iOS,/ && /id:/ && !/placeholder/ && !/Any iOS Device/ {
    for (i = 1; i <= NF; i++) {
      gsub(/^ +| +$/, "", $i)
      if ($i ~ /^id:/) {
        sub(/^id:/, "", $i)
        print $i
        exit
      }
    }
  }' <<< "${destinations}")"

    if [[ -n "${device_id}" ]]; then
      destination="platform=iOS,id=${device_id}"
      echo "Using connected iOS device: ${device_id}"
    else
      destination="generic/platform=iOS"
      echo "No connected iOS device destination found. Using generic iOS device build."
    fi
  fi
fi

xcodebuild build \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -destination "${destination}" \
  -derivedDataPath "${DERIVED_DATA_PATH}"
