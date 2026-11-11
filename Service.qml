import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool connected: false
  property string serial: ""
  property string model: ""
  property string name: ""
  property bool isWifi: false
  property int batteryLevel: 0
  property bool isCharging: false
  property bool webcamRunning: false
  property bool mirrorRunning: false
  property bool audioRunning: false
  property string currentCamera: "back"
  property bool torchOn: false

  property var deviceList: []
  property string rawDevicesJson: ""

  function refresh() {
    statusProc.running = true
    devicesProc.running = true
  }

  Process {
    id: statusProc
    command: [Quickshell.env("HOME") + "/.local/bin/omarchy-android-ctl", "status"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var data = JSON.parse(value)
          root.connected = !!data.connected
          root.serial = data.serial || ""
          root.model = data.model || ""
          root.name = data.name || data.model || ""
          root.isWifi = !!data.is_wifi
          root.batteryLevel = data.battery ? data.battery.level : 0
          root.isCharging = data.battery ? !!data.battery.charging : false
          root.webcamRunning = !!data.webcam_running
          root.mirrorRunning = !!data.mirror_running
          root.audioRunning = !!data.audio_running
          root.currentCamera = data.current_camera || "back"
          root.torchOn = !!data.torch_on
        } catch (e) {}
      }
    }
  }

  Process {
    id: devicesProc
    command: [Quickshell.env("HOME") + "/.local/bin/omarchy-android-ctl", "devices"]
    stdout: StdioCollector {
      onDataChanged: {
        try {
          var data = JSON.parse(value)
          root.deviceList = data.devices || []
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 3000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.refresh()
}
