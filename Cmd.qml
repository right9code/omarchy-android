import QtQuick
import Quickshell.Io

Item {
  id: root
  visible: false
  property bool busy: false
  property var chunks: []
  signal finished(int code, string output)

  function run(args) {
    if (busy) return false
    chunks = []
    busy = true
    proc.command = args
    proc.running = true
    return true
  }

  Process {
    id: proc
    stdout: SplitParser {
      onRead: data => {
        root.chunks.push(data)
      }
    }
    onExited: (code, status) => {
      var res = root.chunks.join("\n").trim()
      root.busy = false
      root.finished(code, res)
    }
  }
}
