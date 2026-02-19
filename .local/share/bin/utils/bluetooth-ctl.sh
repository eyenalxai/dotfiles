#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/json-escape.sh"

bluetooth_devices() {
	local filter="${1:-}"
	local devices_cmd
	if [[ -n "$filter" ]]; then
		devices_cmd="devices $filter"
	else
		devices_cmd="devices"
	fi
	timeout 3 bluetoothctl <<<"$devices_cmd"$'\nquit' 2>&1 | grep -E '^Device' || true
}

bluetooth_info() {
	local mac="$1"
	[[ -z "$mac" ]] && return 1
	timeout 3 bluetoothctl <<<"info $mac"$'\nquit' 2>&1 | grep -v '^\[' || true
}
