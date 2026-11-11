import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarIconButton {
  id: root

  property var androidService: null

  // Use OpticalGlyph text property
  text: (androidService && androidService.webcamRunning) ? "󰄀" : ((androidService && androidService.isWifi) ? "󰖩" : "󰌘")
  active: androidService ? androidService.connected : false

  tooltipText: {
    if (!androidService || !androidService.connected) {
      return "Android: Disconnected"
    }
    var msg = (androidService.model || "Android") + " (" + (androidService.isWifi ? "Wi-Fi" : "USB") + ")"
    msg += " · Battery: " + androidService.batteryLevel + "%"
    if (androidService.webcamRunning) msg += " · 📷 Webcam Active (" + androidService.currentCamera + ")"
    if (androidService.mirrorRunning) msg += " · 📱 Mirror Active"
    return msg
  }

  onPressed: function(btn) {
    if (root.bar && root.bar.shell) {
      root.bar.shell.toggle("right9code.android", "")
    }
  }

  Component.onCompleted: {
    if (root.bar && root.bar.shell) {
      androidService = root.bar.shell.service("right9code.android")
    }
  }
}
