#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-boot}"
PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro Max}"
SIMULATOR_OS="${SIMULATOR_OS:-26.5}"

find_device_id() {
  local preferred_id
  preferred_id="$(xcrun simctl list devices available | awk -v name="${SIMULATOR_NAME}" -v os="${SIMULATOR_OS}" '
    /^-- / {
      in_os = os == "" || index($0, "iOS " os)
      next
    }
    in_os && index($0, name " (") && $0 ~ /\((Booted|Shutdown)\)/ {
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

build_setting() {
  local key="$1"
  xcodebuild -showBuildSettings \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    2>/dev/null \
    | awk -F'= ' -v key="${key}" '$1 ~ "^[[:space:]]*" key "[[:space:]]*$" { print $2; exit }'
}

run_xcodebuild() {
  local log_file
  log_file="$(mktemp -t my-year-xcodebuild.XXXXXX.log)"

  if xcodebuild "$@" >"${log_file}" 2>&1; then
    rm -f "${log_file}"
    return
  fi

  cat "${log_file}" >&2
  rm -f "${log_file}"
  return 1
}

DEVICE_ID="$(find_device_id)"

if [[ -z "${DEVICE_ID}" ]]; then
  echo "No available iPhone simulator found for ${SIMULATOR_NAME} iOS ${SIMULATOR_OS}." >&2
  exit 1
fi

echo "Using simulator: ${DEVICE_ID}"
xcrun simctl boot "${DEVICE_ID}" 2>/dev/null || true
open -a Simulator

if [[ "${COMMAND}" == "build" || "${COMMAND}" == "run" ]]; then
  echo "Building ${SCHEME} for ${SIMULATOR_NAME} iOS ${SIMULATOR_OS}..."
  run_xcodebuild build \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}"
  echo "Build succeeded."
fi

if [[ "${COMMAND}" == "run" ]]; then
  target_build_dir="$(build_setting TARGET_BUILD_DIR)"
  wrapper_name="$(build_setting WRAPPER_NAME)"
  bundle_id="$(build_setting PRODUCT_BUNDLE_IDENTIFIER)"
  app_path="${target_build_dir}/${wrapper_name}"
  info_plist="${app_path}/Info.plist"

  if [[ ! -d "${app_path}" ]]; then
    echo "Built app not found: ${app_path}" >&2
    exit 1
  fi

  version="$(plutil -extract CFBundleShortVersionString raw "${info_plist}" 2>/dev/null || echo "unknown")"
  build="$(plutil -extract CFBundleVersion raw "${info_plist}" 2>/dev/null || echo "unknown")"

  echo "App: ${app_path}"
  echo "Bundle: ${bundle_id}"
  echo "Version: ${version} (${build})"

  echo "Installing app..."
  xcrun simctl install "${DEVICE_ID}" "${app_path}"
  echo "Launching app..."
  xcrun simctl launch "${DEVICE_ID}" "${bundle_id}"
elif [[ "${COMMAND}" == "test" ]]; then
  echo "Testing ${SCHEME} on ${SIMULATOR_NAME} iOS ${SIMULATOR_OS}..."
  run_xcodebuild test \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}"
  echo "Tests succeeded."
elif [[ "${COMMAND}" != "boot" && "${COMMAND}" != "build" ]]; then
  echo "Unknown command: ${COMMAND}. Use 'boot', 'build', 'run', or 'test'." >&2
  exit 1
fi
