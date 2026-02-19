#!/usr/bin/env bash

json_escape() {
	local s="${1-}"
	s=${s//\\/\\\\}
	s=${s//"/\\"/}
	s=${s//$'\n'/\\n}
	printf '%s' "$s"
}
