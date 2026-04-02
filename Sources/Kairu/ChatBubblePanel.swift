import AppKit
import SwiftUI

final class ChatBubblePanel: NSPanel {
    init<Content: View>(contentView: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 340),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let rect = NSRect(x: 0, y: 0, width: 260, height: 340)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = rect
        self.contentView = hostingView
    }

    func show() {
        makeKeyAndOrderFront(nil)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
