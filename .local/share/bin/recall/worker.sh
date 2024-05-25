#!/usr/bin/env bash

set -euo pipefail

SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Recall/Screenshots"
TEXTS_DIR="$(xdg-user-dir PICTURES)/Recall/Texts"

SCREENSHOT_FILE="${SCREENSHOTS_DIR}/$(date +%Y-%m-%d_%H-%M-%S).png"
gnome-screenshot -f "${SCREENSHOT_FILE}"

WEBP_FILE="${SCREENSHOT_FILE%.png}.webp"
cwebp "${SCREENSHOT_FILE}" -q 60 -o "${WEBP_FILE}"
rm "${SCREENSHOT_FILE}"

BASE_FILENAME=$(basename "${WEBP_FILE}" .webp)
TEXT_FILE="${TEXTS_DIR}/${BASE_FILENAME}"

tesseract "${WEBP_FILE}" "${TEXT_FILE}"

echo "Screenshot saved to: ${WEBP_FILE}"
echo "Text extracted to: ${TEXT_FILE}"

DAYS_OLD=30

SCREENSHOTS_DELETED=$(find "${SCREENSHOTS_DIR}" -type f -name '*.webp' -mtime +${DAYS_OLD} -exec rm {} \; -print | wc -l)
TEXTS_DELETED=$(find "${TEXTS_DIR}" -type f -mtime +${DAYS_OLD} -exec rm {} \; -print | wc -l)

echo "${SCREENSHOTS_DELETED} screenshot(s) and ${TEXTS_DELETED} text file(s) older than ${DAYS_OLD} days were deleted."

