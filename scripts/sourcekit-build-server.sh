#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
PROJECT_ROOT="$(pwd -P)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${PROJECT_ROOT}/DerivedData}"
DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"

xcode_build_server_path="$(command -v xcode-build-server || true)"

if [[ -z "${xcode_build_server_path}" ]]; then
  echo "xcode-build-server is not installed or not on PATH." >&2
  exit 1
fi

build_log="$(mktemp -t my-year-sourcekit-build.XXXXXX.log)"
trap 'rm -f "${build_log}"' EXIT

echo "Building ${SCHEME} for ${DESTINATION}..."
if xcodebuild build \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  >"${build_log}" 2>&1; then
  echo "Build succeeded."
else
  cat "${build_log}" >&2
  exit 1
fi

echo "Parsing compiler arguments for SourceKit..."
xcode-build-server parse -a "${build_log}" --skip-validate-bin

cat >buildServer.json <<JSON
{
  "name": "xcode build server",
  "version": "1.3.0",
  "bspVersion": "2.2.0",
  "languages": [
    "c",
    "cpp",
    "objective-c",
    "objective-cpp",
    "swift"
  ],
  "argv": [
    "${xcode_build_server_path}"
  ],
  "workspace": "${PROJECT_ROOT}/${PROJECT}/project.xcworkspace",
  "build_root": "${DERIVED_DATA_PATH}",
  "kind": "manual",
  "scheme": "${SCHEME}",
  "indexStorePath": "${DERIVED_DATA_PATH}/Index.noindex/DataStore"
}
JSON

echo "Updated buildServer.json and .compile for ${PROJECT} (${SCHEME})."
