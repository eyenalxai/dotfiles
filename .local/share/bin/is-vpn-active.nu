#!/usr/bin/env nu

if (do { networkctl status wg0 } | complete | get exit_code) == 0 {
  return "VPN"
}
