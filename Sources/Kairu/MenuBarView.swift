import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject private var config = KairuConfig.shared
    @State private var isRecordingHotkey = false

    var body: some View {
        // Connection status
        HStack(spacing: 4) {
            Circle()
                .fill(appDelegate.chatViewModel.isConnected ? .green : .orange)
                .frame(width: 8, height: 8)
            Text(appDelegate.chatViewModel.isConnected ? "OpenClaw 接続中" : "OpenClaw 未接続")
        }

        Divider()

        Toggle(
            appDelegate.isDolphinVisible ? "イルカを隠す" : "イルカを表示",
            isOn: Binding(
                get: { appDelegate.isDolphinVisible },
                set: { _ in appDelegate.toggleDolphin() }
            )
        )

        Button("チャットを開く (\(config.hotkeyDescription))") {
            appDelegate.activateChat()
        }

        Divider()

        // Hotkey setting
        Button(isRecordingHotkey ? "キーを押してください..." : "ショートカット変更: \(config.hotkeyDescription)") {
            isRecordingHotkey = true
            listenForHotkey()
        }

        Divider()

        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    /// Listen for the next key press to set as the new hotkey
    private func listenForHotkey() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            // Require at least one modifier
            guard !mods.isEmpty else { return event }

            Task { @MainActor in
                config.hotkeyModifiers = Int(mods.rawValue)
                config.hotkeyKeyCode = Int(event.keyCode)
                appDelegate.registerGlobalHotkey()
                isRecordingHotkey = false
            }
            return nil // consume the event
        }
    }
}
