import AppKit
import SwiftUI

/// A non-interactive NSImageView that passes all mouse events through
/// so the parent NSPanel can handle dragging.
final class PassthroughImageView: NSImageView {
    override func mouseDown(with event: NSEvent) {
        superview?.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        superview?.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        superview?.mouseUp(with: event)
    }

    override var mouseDownCanMoveWindow: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Return nil so the window handles the drag instead of this view
        return nil
    }
}

/// NSViewRepresentable that plays animated GIF files using NSImageView.
struct AnimatedGIFView: NSViewRepresentable {
    let gifName: String

    func makeNSView(context: Context) -> PassthroughImageView {
        let imageView = PassthroughImageView()
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.canDrawSubviewsIntoLayer = true
        imageView.isEditable = false
        loadGIF(into: imageView)
        return imageView
    }

    func updateNSView(_ nsView: PassthroughImageView, context: Context) {
        if let current = nsView.accessibilityLabel(), current != gifName {
            loadGIF(into: nsView)
        }
    }

    private func loadGIF(into imageView: PassthroughImageView) {
        imageView.setAccessibilityLabel(gifName)

        guard let url = Bundle.module.url(forResource: gifName, withExtension: "gif") else {
            if let pngURL = Bundle.module.url(forResource: "kairu", withExtension: "png"),
               let img = NSImage(contentsOf: pngURL) {
                imageView.image = img
            }
            return
        }

        guard let image = NSImage(contentsOf: url) else { return }
        imageView.image = image
        imageView.animates = true
    }
}
