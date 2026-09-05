import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  // The Hyprland monitor this bar instance is drawn on. Each bar surface lives
  // on one screen, so we scope the workspace indicators to that monitor's set.
  readonly property string ownScreenName: {
    var w = root.QsWindow ? root.QsWindow.window : null
    return (w && w.screen) ? String(w.screen.name || "") : ""
  }

  readonly property var ownMonitor: {
    if (ownScreenName === "") return null
    var monitors = Hyprland.monitors.values
    for (var i = 0; i < monitors.length; i++) {
      if (String(monitors[i].name || "") === ownScreenName) return monitors[i]
    }

    return null
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  // Workspaces belonging to this monitor, sorted by id. With per-monitor
  // workspaces enabled, the left monitor owns 1-9 and the right owns 10-18,
  // so this list holds exactly nine entries per screen.
  function monitorWorkspaces() {
    var result = []
    var mon = root.ownMonitor
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      if (!mon || !ws || !ws.monitor) continue
      if (ws.monitor.id === mon.id) result.push(ws)
    }

    result.sort(function(left, right) { return left.id - right.id })
    return result
  }

  function workspaceIds() {
    var list = monitorWorkspaces()
    if (list.length === 0) return [1, 2, 3, 4, 5, 6, 7, 8, 9]

    var ids = []
    for (var i = 0; i < list.length; i++) ids.push(list[i].id)
    return ids
  }

  // 1-based local workspace number (1..9) for a given global workspace id.
  function localNumber(id) {
    var list = monitorWorkspaces()
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id) return i + 1
    }

    return id
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: {
          var mon = root.ownMonitor
          return mon !== null && mon.activeWorkspace !== null && mon.activeWorkspace.id === modelData
        }

        bar: root.bar
        text: String(root.localNumber(modelData))
        dimmed: !occupied && !focused
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

        Rectangle {
          visible: focused
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(2)
          width: Style.space(12)
          height: Style.space(2)
          radius: height / 2
          color: Color.accent
        }
      }
    }
  }
}
