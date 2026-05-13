#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-boot}"
PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"

find_device_id() {
  local preferred_id
  preferred_id="$(xcrun simctl list devices available | awk -v name="${SIMULATOR_NAME}" '
    index($0, name " (") && $0 ~ /\((Booted|Shutdown)\)/ {
      match($0, /\([0-9A-F-]{36}\)/)
      if (RSTART) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  ')"

  if [[ -n "${preferred_id}" ]]; then
    echo "${preferred_id}"
    return
  fi

  xcrun simctl list devices available | awk '
    /iPhone/ && $0 ~ /\((Booted|Shutdown)\)/ {
      match($0, /\([0-9A-F-]{36}\)/)
      if (RSTART) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  '
}

DEVICE_ID="$(find_device_id)"

if [[ -z "${DEVICE_ID}" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

echo "Using simulator: ${DEVICE_ID}"
xcrun simctl boot "${DEVICE_ID}" 2>/dev/null || true
open -a Simulator

if [[ "${COMMAND}" == "test" ]]; then
  xcodebuild test \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}"
elif [[ "${COMMAND}" != "boot" ]]; then
  echo "Unknown command: ${COMMAND}. Use 'boot' or 'test'." >&2
  exit 1
fi
