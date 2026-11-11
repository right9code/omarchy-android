import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "right9code.android"
  ipcTarget: "right9code.android"
  manageIpc: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string currentTab: "devices"

  // Live state
  property bool connected: false
  property string serial: ""
  property string model: ""
  property string name: ""
  property bool hasCamera: true
  property bool isWifi: false
  property int batteryLevel: 0
  property bool isCharging: false
  property bool webcamRunning: false
  property bool mirrorRunning: false
  property bool audioRunning: false
  property string currentCamera: "back"
  property bool torchOn: false
  property var deviceList: []

  readonly property string ctlPath: Quickshell.env("HOME") + "/.local/bin/omarchy-android-ctl"

  function refresh() {
    statusCmd.run([root.ctlPath, "status"])
    devicesCmd.run([root.ctlPath, "devices"])
  }

  function runCmd(args) {
    actionCmd.run([root.ctlPath].concat(args))
  }

  Cmd {
    id: statusCmd
    onFinished: function(code, output) {
      if (code === 0 && output) {
        try {
          var data = JSON.parse(output)
          root.connected = !!data.connected
          root.serial = data.serial || ""
          root.model = data.model || ""
          root.name = data.name || data.model || ""
          root.hasCamera = data.has_camera !== false
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

  Cmd {
    id: devicesCmd
    onFinished: function(code, output) {
      if (code === 0 && output) {
        try {
          var data = JSON.parse(output)
          root.deviceList = data.devices || []
        } catch (e) {}
      }
    }
  }

  Cmd {
    id: actionCmd
    onFinished: function(code, output) {
      root.refresh()
    }
  }

  Timer {
    interval: 2500
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: {
    if (opened) root.refresh()
  }

  Component.onCompleted: root.refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.webcamRunning ? "󰄀" : (root.isWifi ? "󰖩" : "󰌘")
    active: root.connected
    tooltipText: {
      if (!root.connected) return "Android: Disconnected"
      var msg = (root.name || root.model || "Android") + " (" + (root.isWifi ? "Wi-Fi" : "USB") + ")"
      msg += " · " + root.batteryLevel + "%"
      if (root.webcamRunning) msg += " · 📷 Cam Active"
      return msg
    }
    onPressed: function(b) {
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(popupLayout.implicitHeight + Style.space(24))

    ColumnLayout {
      id: popupLayout
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(10)

      // Top Quick Connection Header / Status Bar
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          Text {
            text: root.connected ? (root.name || root.model || "Android Phone") : "No Device Connected"
            font.bold: true
            font.pixelSize: Style.font.body
            color: root.connected ? Commons.Color.accent : Commons.Color.urgent
          }
          Text {
            text: root.connected ? (root.serial + " · " + (root.isWifi ? "Wi-Fi" : "USB")) : "Connect via USB or Wi-Fi below"
            font.pixelSize: Style.font.caption - 1
            color: "#9399b2"
          }
        }

        // Quick Action buttons on Top
        Button {
          text: "🔄 Restart ADB"
          onClicked: root.runCmd(["restart-adb"])
        }

        Button {
          visible: root.isWifi
          text: "🔌 Disconnect Wi-Fi"
          onClicked: root.runCmd(["disconnect-wifi"])
        }

        Button {
          visible: !root.isWifi && root.connected
          text: "📶 Go Wi-Fi"
          onClicked: root.runCmd(["switch-to-wifi"])
        }
      }

      // Tab navigation buttons
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)

        Button {
          Layout.fillWidth: true
          text: "📱 Devices"
          selected: root.currentTab === "devices"
          onClicked: root.currentTab = "devices"
        }
        Button {
          Layout.fillWidth: true
          text: "📷 Cam"
          selected: root.currentTab === "webcam"
          onClicked: root.currentTab = "webcam"
        }
        Button {
          Layout.fillWidth: true
          text: "🖥️ Screen"
          selected: root.currentTab === "mirror"
          onClicked: root.currentTab = "mirror"
        }
        Button {
          Layout.fillWidth: true
          text: "📁 Files"
          selected: root.currentTab === "files"
          onClicked: root.currentTab = "files"
        }
        Button {
          Layout.fillWidth: true
          text: "🛠️ Tools"
          selected: root.currentTab === "tools"
          onClicked: root.currentTab = "tools"
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#45475a"
      }

      // --- TAB 1: DEVICES & CONNECTION MANAGER ---
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.currentTab === "devices"
        spacing: Style.space(8)

        Text {
          text: "Connected ADB Devices (" + (root.deviceList.length > 0 ? root.deviceList.length : (root.connected ? 1 : 0)) + ")"
          font.bold: true
          font.pixelSize: Style.font.caption
          color: root.barForeground
        }

        // List of attached devices
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Repeater {
            model: root.deviceList.length > 0 ? root.deviceList : [
              {
                "serial": root.serial,
                "name": root.name || root.model || "Android Device",
                "is_active": true
              }
            ]
            delegate: RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(6)
              visible: modelData.serial !== ""

              Text {
                text: (modelData.is_active ? "🟢 " : "⚪ ") + modelData.name + " (" + modelData.serial + ")"
                color: modelData.is_active ? Commons.Color.accent : root.barForeground
                font.bold: modelData.is_active
                font.pixelSize: Style.font.caption
                Layout.fillWidth: true
              }

              Button {
                text: modelData.is_active ? "Active" : "Select"
                enabled: !modelData.is_active
                onClicked: root.runCmd(["select-device", modelData.serial])
              }
            }
          }
        }

        // Rename active device
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)
          visible: root.connected

          Controls.TextField {
            id: renameInput
            Layout.fillWidth: true
            placeholderText: "Custom Device Name (e.g. My Phone)"
          }

          Button {
            text: "Rename"
            onClicked: {
              if (renameInput.text.trim() !== "" && root.serial !== "") {
                root.runCmd(["rename-device", root.serial, renameInput.text.trim()])
                renameInput.text = ""
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: "#313244"
        }

        Text {
          text: "Connect to Wireless Device"
          font.bold: true
          font.pixelSize: Style.font.caption
          color: root.barForeground
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Controls.TextField {
            id: ipField
            Layout.fillWidth: true
            placeholderText: "Phone IP (e.g. 192.168.1.50:5555)"
          }

          Button {
            text: "Connect IP"
            onClicked: {
              if (ipField.text.trim() !== "") {
                root.runCmd(["connect-wifi", ipField.text.trim()])
              }
            }
          }
        }
      }

      // --- TAB 2: WEBCAM ---
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.currentTab === "webcam"
        spacing: Style.space(8)

        // Notice when device has no hardware cameras
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: Style.space(36)
          radius: 8
          color: "#313244"
          visible: !root.hasCamera

          RowLayout {
            anchors.fill: parent
            anchors.margins: Style.space(8)
            spacing: Style.space(6)

            Text {
              text: "⚠️"
              font.pixelSize: Style.font.body
            }
            Text {
              text: "No hardware cameras detected on this device (" + root.model + ")."
              color: "#fab387"
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
            }
          }
        }

        Text {
          text: !root.hasCamera ? "Webcam: Unavailable (No Camera Sensor)" : (root.webcamRunning ? "Webcam Status: ACTIVE (/dev/video2)" : "Webcam Status: STOPPED")
          color: !root.hasCamera ? "#6c7086" : (root.webcamRunning ? Commons.Color.accent : "#a6adc8")
          font.pixelSize: Style.font.caption
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: root.webcamRunning ? "⏹ Stop Webcam" : "▶ Start Webcam"
            enabled: root.hasCamera
            opacity: root.hasCamera ? 1.0 : 0.4
            onClicked: {
              if (root.webcamRunning) {
                root.runCmd(["webcam-stop"])
              } else {
                root.runCmd(["webcam-start", "back", "call"])
              }
            }
          }

          Button {
            Layout.fillWidth: true
            text: "🔄 Flip Cam (" + (root.currentCamera === "back" ? "Back" : "Front") + ")"
            enabled: root.hasCamera && root.webcamRunning
            opacity: (root.hasCamera && root.webcamRunning) ? 1.0 : 0.4
            onClicked: root.runCmd(["webcam-flip"])
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: root.torchOn ? "💡 Torch: ON" : "💡 Torch: OFF"
            enabled: root.hasCamera
            opacity: root.hasCamera ? 1.0 : 0.4
            onClicked: root.runCmd(["torch-toggle"])
          }

          Button {
            Layout.fillWidth: true
            text: "4K Sharp"
            enabled: root.hasCamera
            opacity: root.hasCamera ? 1.0 : 0.4
            onClicked: root.runCmd(["webcam-start", "back", "sharp"])
          }

          Button {
            Layout.fillWidth: true
            text: "720p Saver"
            enabled: root.hasCamera
            opacity: root.hasCamera ? 1.0 : 0.4
            onClicked: root.runCmd(["webcam-start", "back", "saver"])
          }
        }

        Text {
          text: root.hasCamera ? "Select 'PhoneWebcam' (/dev/video2) in your browser call." : "Connect a phone with a camera to enable virtual webcam streaming."
          font.pixelSize: 11
          color: "#9399b2"
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }

      // --- TAB 3: MIRROR ---
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.currentTab === "mirror"
        spacing: Style.space(8)

        Text {
          text: "Screen Mirroring & Remote Input"
          font.pixelSize: Style.font.caption
          color: root.barForeground
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: root.mirrorRunning ? "⏹ Close Mirror" : "📱 Open Mirror"
            onClicked: {
              if (root.mirrorRunning) {
                root.runCmd(["mirror-stop"])
              } else {
                root.runCmd(["mirror-start"])
              }
            }
          }

          Button {
            Layout.fillWidth: true
            text: "🕶️ Mirror Screen-Off"
            onClicked: root.runCmd(["mirror-start", "--screen-off"])
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: root.audioRunning ? "⏹ Stop Sound" : "🔊 Route Audio Only"
            onClicked: {
              if (root.audioRunning) {
                root.runCmd(["audio-stop"])
              } else {
                root.runCmd(["audio-start"])
              }
            }
          }
        }
      }

      // --- TAB 4: FILES & APKS ---
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.currentTab === "files"
        spacing: Style.space(8)

        Text {
          text: "Right-click any file in Nautilus -> Scripts -> 'Send to Android Phone' to push straight to Download folder."
          font.pixelSize: Style.font.caption
          color: root.barForeground
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }

        Button {
          Layout.fillWidth: true
          text: "📂 Open Downloads in Nautilus"
          onClicked: {
            actionCmd.run(["nautilus", Quickshell.env("HOME") + "/Downloads"])
          }
        }
      }

      // --- TAB 5: TOOLS ---
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.currentTab === "tools"
        spacing: Style.space(8)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: "📸 Screenshot"
            onClicked: root.runCmd(["screenshot-take"])
          }

          Button {
            Layout.fillWidth: true
            text: "🔔 Ring Phone"
            onClicked: root.runCmd(["device-ring"])
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: "🔒 Lock Phone"
            onClicked: root.runCmd(["device-lock"])
          }

          Button {
            Layout.fillWidth: true
            text: "📶 USB Tether"
            onClicked: root.runCmd(["tether-toggle"])
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Controls.TextField {
            id: textInput
            Layout.fillWidth: true
            placeholderText: "Type text or URL to inject..."
            onAccepted: {
              if (text.trim() !== "") {
                root.runCmd(["text-send", text])
                text = ""
              }
            }
          }

          Button {
            text: "Send"
            onClicked: {
              if (textInput.text.trim() !== "") {
                root.runCmd(["text-send", textInput.text])
                textInput.text = ""
              }
            }
          }
        }
      }
    }
  }
}
