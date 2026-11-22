#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "run with sudo: sudo ./fedora/vi-wendy/scripts/remove-teamviewer.sh" >&2
  exit 1
fi

printf '\n======== Stop service ========\n'
systemctl disable --now teamviewerd.service 2>/dev/null || true

printf '\n======== Remove package ========\n'
dnf -y --disablerepo=anydesk --disablerepo=phracek-PyCharm remove teamviewer || rpm -e teamviewer

printf '\n======== Clean residual paths ========\n'
rm -rf /opt/teamviewer /etc/teamviewer /etc/yum.repos.d/teamviewer.repo
systemctl daemon-reload

printf '\n======== Verify ========\n'
echo "packages:"
rpm -qa '*teamviewer*' || true
echo "service:"
systemctl status teamviewerd.service --no-pager 2>&1 || true
echo "listeners:"
ss -tulpen 2>/dev/null | grep -i teamviewer || true
echo "storage:"
df -h /
