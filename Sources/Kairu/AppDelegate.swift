import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var dolphinPanel: DolphinPanel?
    private var chatBubblePanel: ChatBubblePanel?
    let chatViewModel = ChatViewModel()
    @Published var isDolphinVisible = true
    @Published var isChatVisible = false
    @Published var dolphinState: DolphinAnimationState = .idle

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        chatViewModel.$isThinking
            .receive(on: RunLoop.main)
            .sink { [weak self] thinking in
                self?.dolphinState = thinking ? .thinking : .idle
            }
            .store(in: &cancellables)

        setupDolphinPanel()
        setupChatBubblePanel()
        observeDolphinMovement()
    }

    private func setupDolphinPanel() {
        let dolphinView = DolphinSyncView(appDelegate: self)
        dolphinPanel = DolphinPanel(contentView: dolphinView)
        dolphinPanel?.show()
    }

    private func setupChatBubblePanel() {
        let chatView = ChatBubbleView(viewModel: chatViewModel, onClose: { [weak self] in
            self?.toggleChat()
        })
        chatBubblePanel = ChatBubblePanel(contentView: chatView)
    }

    func toggleChat() {
        isChatVisible.toggle()
        if isChatVisible {
            dolphinState = .greeting
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.chatViewModel.isThinking == false {
                    self?.dolphinState = .idle
                }
            }
            positionChatBubble()
            chatBubblePanel?.show()
        } else {
            chatBubblePanel?.orderOut(nil)
            dolphinState = .idle
        }
    }

    func toggleDolphin() {
        isDolphinVisible.toggle()
        if isDolphinVisible {
            dolphinPanel?.show()
        } else {
            dolphinPanel?.orderOut(nil)
            chatBubblePanel?.orderOut(nil)
            isChatVisible = false
        }
    }

    private func observeDolphinMovement() {
        // Follow dolphin with chat bubble
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: dolphinPanel)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Save position on every move
                self.dolphinPanel?.savePosition()
                if self.isChatVisible {
                    self.positionChatBubble()
                }
            }
            .store(in: &cancellables)
    }

    private func positionChatBubble() {
        guard let dolphinFrame = dolphinPanel?.frame else { return }
        let chatWidth: CGFloat = 260
        let chatHeight: CGFloat = 340

        // Position above the dolphin
        var x = dolphinFrame.origin.x + (dolphinFrame.width - chatWidth) / 2
        var y = dolphinFrame.origin.y + dolphinFrame.height + 4

        // Clamp to screen bounds
        if let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(dolphinFrame) })
            ?? NSScreen.main
        {
            let sf = screen.visibleFrame
            x = min(max(x, sf.minX), sf.maxX - chatWidth)
            y = min(max(y, sf.minY), sf.maxY - chatHeight)

            // If not enough room above, put below
            if y + chatHeight > sf.maxY {
                y = dolphinFrame.origin.y - chatHeight - 4
            }
        }

        chatBubblePanel?.setFrame(
            NSRect(x: x, y: y, width: chatWidth, height: chatHeight),
            display: true
        )
    }
}

/// Wrapper view that observes AppDelegate's animation state
struct DolphinSyncView: View {
    @ObservedObject var appDelegate: AppDelegate

    var body: some View {
        DolphinView(
            onTap: { appDelegate.toggleChat() },
            animationState: appDelegate.dolphinState
        )
    }
}
