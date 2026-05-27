#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-run}"
PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"

find_device_id() {
  if [[ -n "${DEVICE_ID:-}" ]]; then
    echo "${DEVICE_ID}"
    return
  fi

  xcodebuild -showdestinations \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    2>/dev/null \
    | awk '
      /platform:iOS,/ && $0 !~ /placeholder/ {
        match($0, /id:[^,}]*/)
        if (RSTART) {
          print substr($0, RSTART + 3, RLENGTH - 3)
          exit
        }
      }
    '
}

find_install_device_id() {
  local build_device_id="$1"

  xcrun devicectl list devices \
    --filter "hardwareProperties.udid == '${build_device_id}'" \
    --hide-default-columns \
    --columns identifier \
    --hide-headers \
    2>/dev/null \
    | awk 'NF { print $1; exit }'
}

build_setting() {
  local key="$1"
  xcodebuild -showBuildSettings \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "platform=iOS,id=${DEVICE_ID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    2>/dev/null \
    | awk -F'= ' -v key="${key}" '$1 ~ "^[[:space:]]*" key "[[:space:]]*$" { print $2; exit }'
}

run_xcodebuild() {
  local log_file
  log_file="$(mktemp -t my-year-device-xcodebuild.XXXXXX.log)"

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
  echo "No connected iOS device found. Connect a device or pass DEVICE_ID=..." >&2
  exit 1
fi

echo "Using device: ${DEVICE_ID}"

if [[ "${COMMAND}" == "build" || "${COMMAND}" == "run" ]]; then
  echo "Building ${SCHEME} for connected device..."
  run_xcodebuild build \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "platform=iOS,id=${DEVICE_ID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}"
  echo "Build succeeded."
fi

if [[ "${COMMAND}" == "run" ]]; then
  target_build_dir="$(build_setting TARGET_BUILD_DIR)"
  wrapper_name="$(build_setting WRAPPER_NAME)"
  bundle_id="$(build_setting PRODUCT_BUNDLE_IDENTIFIER)"
  app_path="${target_build_dir}/${wrapper_name}"

  if [[ ! -d "${app_path}" ]]; then
    echo "Built app not found: ${app_path}" >&2
    exit 1
  fi

  install_device_id="$(find_install_device_id "${DEVICE_ID}")"
  if [[ -z "${install_device_id}" ]]; then
    install_device_id="${DEVICE_ID}"
  fi

  echo "App: ${app_path}"
  echo "Bundle: ${bundle_id}"

  echo "Installing app..."
  xcrun devicectl device install app --device "${install_device_id}" "${app_path}"
  echo "Launching app..."
  xcrun devicectl device process launch --device "${install_device_id}" "${bundle_id}"
elif [[ "${COMMAND}" != "build" ]]; then
  echo "Unknown command: ${COMMAND}. Use 'build' or 'run'." >&2
  exit 1
fi
