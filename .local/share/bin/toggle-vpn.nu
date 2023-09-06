#!/usr/bin/env nu

if (do { networkctl status wg0 } | complete | get exit_code) == 0 {
  systemctl stop wg-quick@wg0.service
  echo "Disable VPN"
} else {
  systemctl start wg-quick@wg0.service
  echo "Enabled VPN"
}
