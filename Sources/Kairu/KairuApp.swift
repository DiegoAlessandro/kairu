import SwiftUI

@main
struct KairuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Kairu", systemImage: "bubble.left.and.bubble.right") {
            MenuBarView(appDelegate: appDelegate)
        }
        // No WindowGroup — the app only uses floating panels
        Settings { EmptyView() }
    }
}
