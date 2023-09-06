#!/usr/bin/env nu

if (do { pgrep wf-recorder } | complete | get exit_code) == 0 {
  return "RECORDING"
}

