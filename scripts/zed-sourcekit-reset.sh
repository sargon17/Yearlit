#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

cd "${PROJECT_ROOT}"

"${SCRIPT_DIR}/sourcekit-build-server.sh"

pkill -f "/usr/bin/sourcekit-lsp --default-workspace-type buildServer" 2>/dev/null || true
pkill -f "/opt/homebrew/bin/xcode-build-server" 2>/dev/null || true

echo "Refreshed SourceKit metadata. Reopen a Swift file in Zed or run Developer: Restart Language Servers."
