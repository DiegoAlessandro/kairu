import AppKit
import SwiftUI

final class DolphinPanel: NSPanel {
    init<Content: View>(contentView: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 128),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let rect = NSRect(x: 0, y: 0, width: 140, height: 128)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = rect
        self.contentView = hostingView
    }

    func show() {
        let config = KairuConfig.shared

        if config.hasStoredPosition {
            // Restore saved position, clamped to screen
            let point = NSPoint(x: config.dolphinX, y: config.dolphinY)
            setFrameOrigin(clampToScreen(point))
        } else {
            // Default: bottom-right of main screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.maxX - frame.width - 40
                let y = screenFrame.origin.y + 60
                setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
        makeKeyAndOrderFront(nil)
    }

    /// Save current position to UserDefaults
    func savePosition() {
        let config = KairuConfig.shared
        config.dolphinX = frame.origin.x
        config.dolphinY = frame.origin.y
        config.hasStoredPosition = true
    }

    /// Ensure the point keeps the window visible on any screen
    private func clampToScreen(_ point: NSPoint) -> NSPoint {
        // Find the screen containing the point, or fall back to main screen
        let screen = NSScreen.screens.first {
            $0.visibleFrame.contains(point)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else { return point }

        let x = min(max(point.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
        let y = min(max(point.y, visibleFrame.minY), visibleFrame.maxY - frame.height)
        return NSPoint(x: x, y: y)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
