#!/usr/bin/env nu

if (do { bluetoothctl info E8:EE:CC:38:E9:24 | rg Connected } | split words | get 1) == no {
  bluetoothctl connect E8:EE:CC:38:E9:24 | complete; return Connected
} else {
  bluetoothctl disconnect E8:EE:CC:38:E9:24 | complete; return Disconnected  
}

