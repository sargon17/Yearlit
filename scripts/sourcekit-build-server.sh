#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-My Year.xcodeproj}"
SCHEME="${SCHEME:-My Year}"
PROJECT_ROOT="$(pwd -P)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-}"
DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"

xcode_build_server_path="$(command -v xcode-build-server || true)"

if [[ -z "${xcode_build_server_path}" ]]; then
  echo "xcode-build-server is not installed or not on PATH." >&2
  exit 1
fi

build_log="$(mktemp -t my-year-sourcekit-build.XXXXXX.log)"
trap 'rm -f "${build_log}"' EXIT

echo "Building ${SCHEME} for ${DESTINATION}..."
build_args=(
  build
  -project "${PROJECT}"
  -scheme "${SCHEME}"
  -destination "${DESTINATION}"
)

if [[ -n "${DERIVED_DATA_PATH}" ]]; then
  build_args+=(-derivedDataPath "${DERIVED_DATA_PATH}")
fi

if xcodebuild "${build_args[@]}" >"${build_log}" 2>&1; then
  echo "Build succeeded."
else
  cat "${build_log}" >&2
  exit 1
fi

if [[ -z "${DERIVED_DATA_PATH}" ]]; then
  build_root="$(
    xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -showBuildSettings 2>/dev/null \
      | awk -F' = ' '/^[[:space:]]*BUILD_ROOT = / { print $2; exit }'
  )"
  DERIVED_DATA_PATH="${build_root%/Build/Products}"
fi

echo "Parsing compiler arguments for SourceKit..."
activity_log="$(
  find "${DERIVED_DATA_PATH}/Logs/Build" -name "*.xcactivitylog" -size +0 -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | head -n 1
)"

if [[ -n "${activity_log}" ]]; then
  xcode-build-server parse -l "${activity_log}" --skip-validate-bin >/dev/null 2>&1
else
  echo "No Xcode activity log found under ${DERIVED_DATA_PATH}/Logs/Build; parsing xcodebuild output instead."
  xcode-build-server parse "${build_log}" --skip-validate-bin >/dev/null 2>&1
fi

if [[ ! -s .compile ]] || [[ "$(tr -d '[:space:]' <.compile)" == "[]" ]]; then
  echo "xcode-build-server produced an empty .compile file." >&2
  exit 1
fi

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
