import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject private var config = KairuConfig.shared

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

        Button("ショートカット変更: \(config.hotkeyDescription)") {
            appDelegate.showHotkeyRecorder()
        }

        Divider()

        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
