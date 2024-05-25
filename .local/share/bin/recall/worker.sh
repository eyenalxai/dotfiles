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

DAYS_OLD=30

SCREENSHOTS_DELETED=$(find "${SCREENSHOTS_DIR}" -type f -name '*.png' -mtime +${DAYS_OLD} -exec rm {} \; -print | wc -l)
TEXTS_DELETED=$(find "${TEXTS_DIR}" -type f -mtime +${DAYS_OLD} -exec rm {} \; -print | wc -l)

echo "${SCREENSHOTS_DELETED} screenshot(s) and ${TEXTS_DELETED} text file(s) older than ${DAYS_OLD} days were deleted."
