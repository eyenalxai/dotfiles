#!/usr/bin/env nu
# JSON snapshot of OpenCode Go usage for the bar widget. BarWidget.qml runs this
# under `timeout`, so a hung CLI or network call cannot wedge the widget.
source ~/.config/nushell/autoload/opencode-go-usage.nu
opencode-go-usage --json --history
