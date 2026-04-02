import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Sendable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(text: String, isUser: Bool) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(text: "こんにちは！何について調べますか？ 🐬", isUser: false)
    ]
    @Published var isThinking = false
    @Published var isConnected = false
    @Published private(set) var isSending = false

    // Create new service (with new session ID) on clear
    private var openClawService = OpenClawService()

    func checkConnection() {
        Task {
            let config = OpenClawConnectionConfig.current
            let status = await openClawService.checkHealth(config: config)
            isConnected = status == .connected
        }
    }

    func send(_ text: String) {
        guard !isSending else { return }
        isSending = true

        messages.append(ChatMessage(text: text, isUser: true))
        isThinking = true

        Task {
            let config = OpenClawConnectionConfig.current
            let response = await openClawService.sendMessage(text, config: config)
            isThinking = false
            isSending = false
            messages.append(ChatMessage(text: response, isUser: false))
        }
    }

    func clearHistory() {
        messages = [
            ChatMessage(text: "こんにちは！何について調べますか？ 🐬", isUser: false)
        ]
        // New service = new session ID = fresh OpenClaw context
        openClawService = OpenClawService()
    }
}
