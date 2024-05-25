#!/usr/bin/env bash

set -euo pipefail

SEARCH_DIR="$(xdg-user-dir PICTURES)/Recall/Texts"
SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Recall/Screenshots"

cd "${SEARCH_DIR}"

SELECTED_FILE=$(rg . | fzf --print0 -e | cut -z -d: -f1 | xargs -0 -r echo)

if [[ -z "${SELECTED_FILE}" ]]; then
  echo "No file selected."
  exit 1
fi

SCREENSHOT_FILE="${SELECTED_FILE%.txt}.png"

SCREENSHOT_PATH="${SCREENSHOTS_DIR}/$(basename "${SCREENSHOT_FILE}")"

xdg-open "${SCREENSHOT_PATH}"
