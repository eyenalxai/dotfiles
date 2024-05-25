#!/usr/bin/env bash

set -euo pipefail

SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Recall/Screenshots"
TEXTS_DIR="$(xdg-user-dir PICTURES)/Recall/Texts"

SCREENSHOT_FILE="${SCREENSHOTS_DIR}/$(date +%Y-%m-%d_%H-%M-%S).png"
gnome-screenshot -f "${SCREENSHOT_FILE}"

BASE_FILENAME=$(basename "${SCREENSHOT_FILE}" .png)
TEXT_FILE="${TEXTS_DIR}/${BASE_FILENAME}"

tesseract "${SCREENSHOT_FILE}" "${TEXT_FILE}"

echo "Screenshot saved to: ${SCREENSHOT_FILE}"
echo "Text extracted to: ${TEXT_FILE}"
