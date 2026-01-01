#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/.config/clipse"

# Create timestamped backup of the original file
backup="clipboard_history.json.bak-$(date +%Y%m%d%H%M%S)"
cp "clipboard_history.json" "$backup"

# Create a temporary output file in the same directory
tmp_file="$(mktemp clipboard_history.json.tmp.XXXXXX)"

cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT

# Run jq with a 5-second timeout to scrub the file
if timeout 5s jq '
  def scrub:
    explode
    | map(select(. == 9 or . == 10 or . == 13 or (. >= 32 and . != 127)))
    | implode;
  .clipboardHistory |= map(
    if (.value|type) == "string" then .value |= scrub else . end
  )
' "clipboard_history.json" > "$tmp_file"; then
  mv "$tmp_file" "clipboard_history.json"
  trap - EXIT
  rm -f "$tmp_file"
else
  echo "jq scrub failed; leaving original and backup intact" >&2
  exit 1
fi
