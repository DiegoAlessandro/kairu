import AppKit
import SwiftUI

final class ChatBubblePanel: NSPanel {
    init<Content: View>(contentView: Content) {
        let w = UserDefaults.standard.double(forKey: "bubbleWidth").nonZero ?? 300
        let h = UserDefaults.standard.double(forKey: "bubbleHeight").nonZero ?? 400

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .resizable],
            backing: .buffered,
            defer: false
        )

        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = hostingView
    }

    func show() {
        makeKeyAndOrderFront(nil)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
