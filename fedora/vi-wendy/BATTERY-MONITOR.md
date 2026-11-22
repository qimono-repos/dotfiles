# Battery monitor — vi-wendy

Purpose: measure how long this notebook actually runs unplugged, using UPower telemetry and an observed discharge rate.

## What runs

`systemd --user` service: `qimono-battery-monitor.service`
Script: `scripts/battery-monitor.sh`
Sample interval: 60 seconds by default.

Log locations:

```text
~/.local/state/qimono/battery-monitor/vi-wendy-battery.csv
~/.local/state/qimono/battery-monitor/vi-wendy-summary.txt
```

The CSV is append-only and includes timestamp, state, percent, energy, UPower rate, UPower time-to-empty, AC state, monitor elapsed time, observed discharge rate, estimated remaining minutes, and estimated full-runtime minutes.

## Control

```bash
systemctl --user status qimono-battery-monitor.service
systemctl --user restart qimono-battery-monitor.service
systemctl --user stop qimono-battery-monitor.service
```

Read the current summary:

```bash
sed -n '1,40p' ~/.local/state/qimono/battery-monitor/vi-wendy-summary.txt
```

Change the interval without editing the script:

```bash
mkdir -p ~/.config/systemd/user/qimono-battery-monitor.service.d
printf '[Service]\nEnvironment=QIMONO_BATTERY_INTERVAL=30\n' > ~/.config/systemd/user/qimono-battery-monitor.service.d/interval.conf
systemctl --user daemon-reload
systemctl --user restart qimono-battery-monitor.service
```

## Interpretation

- `upower time to empty` is UPower's short-term estimate.
- `estimated remaining` uses the average discharge observed since the monitor started.
- `estimated full runtime` scales the observed rate to `energy-full`; it improves as the sample window grows.
- Recharge cycles reset the average when the service is restarted.
- If the line is plugged in, `ac online` becomes `yes` and discharge estimates stop being meaningful.

## Limits

This is a user service. It stops at logout unless linger is enabled for the user; enabling linger needs root. The battery is old, so capacity (`energy-full`) and discharge behavior may differ from the original design capacity.
