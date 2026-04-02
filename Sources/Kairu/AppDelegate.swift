import AppKit
import Carbon.HIToolbox
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
    private var globalMonitor: Any?

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
        registerGlobalHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Panel setup

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

    // MARK: - Toggle actions

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
            // Focus the input field
            chatBubblePanel?.makeKey()
        } else {
            chatBubblePanel?.orderOut(nil)
            dolphinState = .idle
        }
    }

    /// Open chat and immediately focus the input (for hotkey)
    func activateChat() {
        if !isDolphinVisible {
            isDolphinVisible = true
            dolphinPanel?.show()
        }
        if !isChatVisible {
            toggleChat()
        } else {
            // Already open — just bring to front and focus
            chatBubblePanel?.makeKey()
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

    // MARK: - Global hotkey

    func registerGlobalHotkey() {
        // Remove existing monitor
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }

        let config = KairuConfig.shared
        let targetMods = NSEvent.ModifierFlags(rawValue: UInt(config.hotkeyModifiers))
            .intersection([.command, .shift, .option, .control])
        let targetKey = UInt16(config.hotkeyKeyCode)

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let eventMods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            if event.keyCode == targetKey && eventMods == targetMods {
                Task { @MainActor in
                    self?.activateChat()
                }
            }
        }
    }

    // MARK: - Dolphin movement tracking

    private func observeDolphinMovement() {
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: dolphinPanel)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.dolphinPanel?.savePosition()
                if self.isChatVisible {
                    self.positionChatBubble()
                }
            }
            .store(in: &cancellables)
    }

    private func positionChatBubble() {
        guard let dolphinFrame = dolphinPanel?.frame,
              let bubbleFrame = chatBubblePanel?.frame else { return }
        let chatWidth = bubbleFrame.width
        let chatHeight = bubbleFrame.height

        var x = dolphinFrame.origin.x + (dolphinFrame.width - chatWidth) / 2
        var y = dolphinFrame.origin.y + dolphinFrame.height + 4

        if let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(dolphinFrame) })
            ?? NSScreen.main
        {
            let sf = screen.visibleFrame
            x = min(max(x, sf.minX), sf.maxX - chatWidth)
            y = min(max(y, sf.minY), sf.maxY - chatHeight)

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
