#!/bin/bash

# Returns formatted battery status string with percentage, power rate (positive magnitude), and time remaining.
# Usage: battery-status.sh [--shell]

shell_output=false
power_supply_path="${OMARCHY_POWER_SUPPLY_PATH:-/sys/class/power_supply}"

case "${1:-}" in
  "")
    ;;
  --shell)
    shell_output=true
    ;;
  *)
    echo "Usage: battery-status.sh [--shell]" >&2
    exit 2
    ;;
esac

battery=$(upower -e 2>/dev/null | grep -iE '/devices/battery' | head -n 1)
[[ -z $battery ]] && exit 0

battery_info=$(upower -i "$battery")

raw_percentage=$(awk '/percentage/ { print $2 + 0; exit }' <<<"$battery_info")
percentage=$(awk -v p="$raw_percentage" 'BEGIN { printf "%d", p + 0.5 }')
capacity=$(awk '/energy-full:/ { printf "%d", $2; exit }' <<<"$battery_info")

# Determine whether UPower reports time to empty or time to full
time_type=$(awk '/time to (empty|full)/ { gsub(/:/, "", $3); print $3; exit }' <<<"$battery_info")

time_remaining=$(awk '/time to (empty|full)/ {
  value = $4
  unit = $5
  if (unit ~ /^minute/) {
    printf "%dm", int(value)
  } else {
    hours = int(value)
    minutes = int((value - hours) * 60)
    if (minutes > 0) {
      printf "%dh %dm", hours, minutes
    } else {
      printf "%dh", hours
    }
  }
  exit
}' <<<"$battery_info")

power_rate_raw=$(awk '/energy-rate/ { print $2; exit }' <<<"$battery_info")
native_path=$(awk '/native-path/ { print $2; exit }' <<<"$battery_info")
battery_path="$power_supply_path/$native_path"

if [[ -r $battery_path/power_now ]]; then
  power_rate_raw=$(awk -v microwatts="$(<"$battery_path/power_now")" 'BEGIN {
    w = microwatts / 1000000
    if (w < 0) w = -w
    print w
  }')
elif [[ -r $battery_path/current_now && -r $battery_path/voltage_now ]]; then
  power_rate_raw=$(awk \
    -v microamps="$(<"$battery_path/current_now")" \
    -v microvolts="$(<"$battery_path/voltage_now")" \
    'BEGIN {
      w = (microamps * microvolts) / 1000000000000
      if (w < 0) w = -w
      print w
    }')
fi

power_rate=$(awk -v rate="${power_rate_raw:-0}" 'BEGIN {
  if (rate < 0) rate = -rate
  rounded = sprintf("%.1f", rate)
  sub(/\.0$/, "", rounded)
  print rounded
}')

state=$(awk '/state/ { print $2; exit }' <<<"$battery_info")

sysfs_end=""
if [[ -r $battery_path/charge_control_end_threshold ]]; then
  sysfs_end=$(<"$battery_path/charge_control_end_threshold")
elif compgen -G "$power_supply_path/BAT*/charge_control_end_threshold" >/dev/null; then
  sysfs_end=$(cat "$power_supply_path"/BAT*/charge_control_end_threshold 2>/dev/null | head -1)
fi

threshold_supported=false
if [[ -n $sysfs_end ]] || grep -qiE 'charge-threshold-supported:\s*yes' <<<"$battery_info"; then
  threshold_supported=true
fi

if [[ -n $sysfs_end ]]; then
  threshold_end="$sysfs_end"
else
  threshold_end=$(awk '/charge-end-threshold:/ { gsub(/%/, "", $2); print int($2); exit }' <<<"$battery_info")
fi

sysfs_start=""
if [[ -r $battery_path/charge_control_start_threshold ]]; then
  sysfs_start=$(<"$battery_path/charge_control_start_threshold")
elif compgen -G "$power_supply_path/BAT*/charge_control_start_threshold" >/dev/null; then
  sysfs_start=$(cat "$power_supply_path"/BAT*/charge_control_start_threshold 2>/dev/null | head -1)
fi

if [[ -n $sysfs_start ]]; then
  threshold_start="$sysfs_start"
else
  threshold_start=$(awk '/charge-start-threshold:/ { gsub(/%/, "", $2); print int($2); exit }' <<<"$battery_info")
fi

ac_online=false
for supply in "$power_supply_path"/*; do
  [[ -r $supply/type ]] || continue
  [[ $(<"$supply/type") == "Mains" ]] || continue
  [[ -r $supply/online ]] || continue

  if [[ $(<"$supply/online") == "1" ]]; then
    ac_online=true
    break
  fi
done

charge_idle=false
if awk -v rate="${power_rate_raw:-0}" 'BEGIN {
  r = rate < 0 ? -rate : rate
  exit !(r <= 0.2)
}'; then
  charge_idle=true
fi

charge_holding=false
if [[ $ac_online == "true" && -n $threshold_end ]]; then
  if [[ $state == "pending-charge" ]]; then
    charge_holding=true
  elif [[ $state == "fully-charged" ]] && awk -v p="$raw_percentage" 'BEGIN { exit !(p < 99) }'; then
    charge_holding=true
  elif [[ $state == "charging" && $charge_idle == "true" ]] && (( threshold_end < 99 )) && awk -v p="$raw_percentage" -v t="$threshold_end" 'BEGIN { exit !(p >= t) }'; then
    charge_holding=true
  elif [[ ( $state == "discharging" || $state == "not-charging" ) && $charge_idle == "true" ]] && (( threshold_end < 99 )) && awk -v p="$raw_percentage" -v t="${threshold_start:-$threshold_end}" 'BEGIN { exit !(p >= t - 1) }'; then
    charge_holding=true
  fi
fi

# If battery state is discharging, ensure time_type defaults to empty
if [[ $state == "discharging" && -z $time_type ]]; then
  time_type="empty"
fi

if [[ $shell_output == "true" ]]; then
  printf 'percentage\t%s\n' "${percentage}%"
  if [[ $charge_holding == "true" ]]; then
    printf 'state\tholding\n'
  else
    printf 'state\t%s\n' "$state"
  fi
  printf 'rate\t%s\n' "${power_rate}W"
  printf 'size\t%s\n' "${capacity}Wh"
  printf 'time\t%s\n' "$time_remaining"
  printf 'time_type\t%s\n' "$time_type"

  cycles=$(cat "$battery_path"/cycle_count 2>/dev/null | head -1)
  [[ -z $cycles ]] && cycles=$(cat "$power_supply_path"/BAT*/cycle_count 2>/dev/null | head -1)

  [[ -n $cycles ]] && printf 'cycles\t%s\n' "$cycles"

  if [[ -n $threshold_end ]]; then
    if (( threshold_end < 99 )); then
      if [[ -n $threshold_start && $threshold_start != $threshold_end ]]; then
        printf 'threshold\t%s-%s%%\n' "$threshold_start" "$threshold_end"
      else
        printf 'threshold\t%s%%\n' "$threshold_end"
      fi
    else
      printf 'threshold\t100%%\n'
    fi
  fi
  printf 'threshold_end\t%s\n' "${threshold_end:-100}"
  printf 'threshold_supported\t%s\n' "$threshold_supported"

  exit 0
fi

if [[ $charge_holding == "true" ]]; then
  if [[ -n $threshold_start && $threshold_start != $threshold_end ]]; then
    threshold_label="${threshold_start}-${threshold_end}%"
  else
    threshold_label="${threshold_end}%"
  fi

  echo "Battery ${percentage}%  ·  Holding at ${threshold_label}  ·  ${power_rate}W / ${capacity}Wh"
elif [[ $state == "charging" ]]; then
  echo "Battery ${percentage}%  ·  ${time_remaining} to full  ·   ${power_rate}W / ${capacity}Wh"
else
  echo "Battery ${percentage}%  ·  ${time_remaining} left  ·   ${power_rate}W / ${capacity}Wh"
fi
