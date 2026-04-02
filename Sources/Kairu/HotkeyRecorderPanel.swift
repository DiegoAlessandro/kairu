import AppKit
import SwiftUI

/// A small floating panel that captures a key combo for the global hotkey.
final class HotkeyRecorderPanel: NSPanel {
    private var localMonitor: Any?
    var onRecorded: ((Int, Int) -> Void)?  // (modifiers, keyCode)

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 100),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        title = "ショートカット設定"
        level = .floating
        isReleasedWhenClosed = false
        center()

        let label = NSTextField(wrappingLabelWithString: "新しいショートカットキーを押してください\n(修飾キー + 文字キー)")
        label.alignment = .center
        label.font = .systemFont(ofSize: 13)
        label.frame = NSRect(x: 20, y: 20, width: 240, height: 60)
        contentView?.addSubview(label)
    }

    func showAndRecord(completion: @escaping (Int, Int) -> Void) {
        onRecorded = completion
        makeKeyAndOrderFront(nil)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !mods.isEmpty else { return event }

            self?.onRecorded?(Int(mods.rawValue), Int(event.keyCode))
            self?.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        orderOut(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        stopRecording()
    }
}
