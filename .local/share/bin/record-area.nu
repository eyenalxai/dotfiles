#!/usr/bin/env nu
if (do { pgrep wf-recorder } | complete | get exit_code) == 1 {
  wf-recorder -c libx264 -g (slurp) -f $"($env.HOME)/Stuff/Recordings/(date now | format date '%Y-%m-%d %H:%M:%S').mp4"
} else {
  pkill wf-recorder
}

