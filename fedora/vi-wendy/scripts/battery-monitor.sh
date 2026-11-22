#!/usr/bin/env bash
set -uo pipefail

battery=${QIMONO_BATTERY_DEVICE:-/org/freedesktop/UPower/devices/battery_axp288_fuel_gauge}
charger=${QIMONO_CHARGER_DEVICE:-/org/freedesktop/UPower/devices/line_power_axp288_charger}
log=${QIMONO_BATTERY_LOG:-$HOME/.local/state/qimono/battery-monitor/vi-wendy-battery.csv}
summary=${QIMONO_BATTERY_SUMMARY:-$HOME/.local/state/qimono/battery-monitor/vi-wendy-summary.txt}
interval=${QIMONO_BATTERY_INTERVAL:-60}

mkdir -p "$(dirname "$log")" "$(dirname "$summary")"

if [[ ! -f "$log" ]]; then
  printf '%s\n' 'timestamp,state,percent,energy_wh,energy_full_wh,rate_w,voltage_v,upower_time_to_empty,ac_online,elapsed_s,avg_discharge_w,est_remaining_min,est_full_runtime_min' > "$log"
fi

first_epoch=""
first_energy=""

while true; do
  info="$(LC_ALL=C upower -i "$battery" 2>/dev/null || true)"
  charger_info="$(LC_ALL=C upower -i "$charger" 2>/dev/null || true)"

  state="$(awk '/^[[:space:]]*state:/ {print $2; exit}' <<<"$info")"
  percent="$(awk '/^[[:space:]]*percentage:/ {gsub(/%/, "", $2); print $2; exit}' <<<"$info")"
  energy="$(awk '/^[[:space:]]*energy:/ {print $2; exit}' <<<"$info")"
  energy_full="$(awk '/^[[:space:]]*energy-full:/ {print $2; exit}' <<<"$info")"
  rate="$(awk '/^[[:space:]]*energy-rate:/ {print $2; exit}' <<<"$info")"
  voltage="$(awk '/^[[:space:]]*voltage:/ {print $2; exit}' <<<"$info")"
  tte="$(awk -F': ' '/^[[:space:]]*time to empty:/ {gsub(/^ +/, "", $2); print $2; exit}' <<<"$info")"
  ac="$(awk '/^[[:space:]]*online:/ {print $2; exit}' <<<"$charger_info")"

  ts="$(date -Is)"
  now="$(date +%s)"

  if [[ -z "$first_epoch" && -n "$energy" ]]; then
    first_epoch=$now
    first_energy=$energy
  fi

  elapsed=""
  avg=""
  remaining=""
  full_runtime=""

  if [[ -n "$first_epoch" && -n "$first_energy" && -n "$energy" && -n "$energy_full" ]]; then
    elapsed=$((now - first_epoch))
    stats="$(awk -v first="$first_energy" -v current="$energy" -v full="$energy_full" -v elapsed="$elapsed" -v state="$state" -v rate="$rate" 'BEGIN { if (state == "discharging") { used = first - current; if (elapsed > 0 && used > 0) { avg = used * 3600 / elapsed } else if (rate ~ /^[0-9.]+$/) { avg = rate } if (avg > 0) { printf "%.3f %.1f %.1f\n", avg, current * 60 / avg, full * 60 / avg } else { printf "n/a n/a n/a\n" } } else { printf "n/a n/a n/a\n" } }')"
    read -r avg remaining full_runtime <<<"$stats"
  fi

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$ts" "$state" "$percent" "$energy" "$energy_full" "$rate" "$voltage" "$tte" "$ac" "$elapsed" "$avg" "$remaining" "$full_runtime" >> "$log"

  {
    printf 'Qimono vi-wendy battery monitor\n'
    printf 'updated: %s\n' "$ts"
    printf 'state: %s\n' "$state"
    printf 'charge: %s%%\n' "$percent"
    printf 'energy: %s Wh / %s Wh\n' "$energy" "$energy_full"
    printf 'upower rate: %s W\n' "$rate"
    printf 'upower time to empty: %s\n' "$tte"
    printf 'ac online: %s\n' "$ac"
    printf 'monitor elapsed: %s s\n' "$elapsed"
    printf 'observed discharge: %s W\n' "$avg"
    printf 'estimated remaining: %s min\n' "$remaining"
    printf 'estimated full runtime: %s min\n' "$full_runtime"
    printf 'csv: %s\n' "$log"
  } > "$summary"

  sleep "$interval"
done
