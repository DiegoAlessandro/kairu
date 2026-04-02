import SwiftUI

// Windows classic UI colors
private let balloonBg = Color(red: 1.0, green: 1.0, blue: 0.88)     // Pale yellow balloon
private let balloonBorder = Color(red: 0.0, green: 0.0, blue: 0.0)   // Black border
private let buttonFace = Color(red: 0.85, green: 0.83, blue: 0.78)   // Windows button gray
private let buttonHighlight = Color.white
private let buttonShadow = Color(red: 0.5, green: 0.5, blue: 0.5)
private let inputBg = Color.white
private let headerText = Color.black

struct ChatBubbleView: View {
    @ObservedObject var viewModel: ChatViewModel
    let onClose: @MainActor () -> Void

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // === Title bar (Windows classic style) ===
            HStack(spacing: 4) {
                Text("何について調べますか？")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(headerText)
                Spacer()
                // Close button (Windows classic X)
                Button(action: onClose) {
                    Text("✕")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 16, height: 16)
                        .background(
                            ClassicButton()
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            // === Messages area ===
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.messages) { message in
                            ClassicMessageRow(message: message)
                                .id(message.id)
                        }
                        if viewModel.isThinking {
                            ThinkingIndicator()
                                .id("thinking")
                        }
                    }
                    .padding(6)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .background(balloonBg)
            .overlay(
                Rectangle()
                    .stroke(buttonShadow, lineWidth: 1)
            )
            .padding(.horizontal, 8)

            Spacer().frame(height: 6)

            // === Input field (Windows classic textbox) ===
            HStack(spacing: 0) {
                TextField("お前を消す方法", text: $inputText)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                    .padding(4)
                    .background(inputBg)
                    .overlay(
                        // Windows classic inset border
                        ClassicInsetBorder()
                    )
            }
            .padding(.horizontal, 8)

            Spacer().frame(height: 8)

            // === Bottom buttons (Windows classic style) ===
            HStack(spacing: 8) {
                // Connection status indicator
                if !viewModel.isConnected {
                    HStack(spacing: 3) {
                        Circle().fill(.orange).frame(width: 5, height: 5)
                        Text("未接続")
                            .font(.system(size: 9))
                            .foregroundStyle(buttonShadow)
                    }
                }

                Spacer()

                // Clear button
                Button(action: { viewModel.clearHistory() }) {
                    Text("クリア(C)")
                        .font(.system(size: 11))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(ClassicButton())
                }
                .buttonStyle(.plain)

                // Search button
                Button(action: sendMessage) {
                    Text("検索(S)")
                        .font(.system(size: 11))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? buttonShadow : .black
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(ClassicButton())
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 260, height: 340)
        .background(balloonBg)
        .overlay(
            // Outer balloon border with classic Windows shadow
            RoundedRectangle(cornerRadius: 4)
                .stroke(balloonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.25), radius: 2, x: 2, y: 2)
        .onAppear {
            isInputFocused = true
            viewModel.checkConnection()
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.send(text)
    }
}

// MARK: - Windows Classic UI Components

/// Windows classic 3D raised button effect
struct ClassicButton: View {
    var body: some View {
        ZStack {
            buttonFace
            // Top-left highlight
            VStack(spacing: 0) {
                Rectangle().fill(buttonHighlight).frame(height: 1)
                Spacer()
            }
            HStack(spacing: 0) {
                Rectangle().fill(buttonHighlight).frame(width: 1)
                Spacer()
            }
            // Bottom-right shadow
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(buttonShadow).frame(height: 1)
            }
            HStack(spacing: 0) {
                Spacer()
                Rectangle().fill(buttonShadow).frame(width: 1)
            }
        }
    }
}

/// Windows classic inset border for text fields
struct ClassicInsetBorder: View {
    var body: some View {
        ZStack {
            // Top-left dark edge (inset effect)
            VStack(spacing: 0) {
                Rectangle().fill(buttonShadow).frame(height: 1)
                Spacer()
            }
            HStack(spacing: 0) {
                Rectangle().fill(buttonShadow).frame(width: 1)
                Spacer()
            }
            // Bottom-right light edge
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(buttonHighlight).frame(height: 1)
            }
            HStack(spacing: 0) {
                Spacer()
                Rectangle().fill(buttonHighlight).frame(width: 1)
            }
        }
    }
}

/// Message display in classic Office assistant style
struct ClassicMessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if message.isUser {
                Spacer(minLength: 30)
                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .padding(5)
                    .background(Color.white)
                    .overlay(ClassicInsetBorder())
            } else {
                HStack(alignment: .top, spacing: 4) {
                    Text("●")
                        .font(.system(size: 6))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                        .padding(.top, 4)
                    MarkdownText(message.text)
                }
                .textSelection(.enabled)
                .padding(.vertical, 2)
                Spacer(minLength: 30)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Renders Markdown text using AttributedString
struct MarkdownText: View {
    let source: String

    init(_ source: String) {
        self.source = source
    }

    var body: some View {
        Text(rendered)
            .font(.system(size: 12))
            .foregroundColor(.black)
            .tint(Color(red: 0.1, green: 0.3, blue: 0.7))
    }

    private var rendered: AttributedString {
        // Try Markdown parsing; fall back to plain text
        if let md = try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return md
        }
        return AttributedString(source)
    }
}

struct ThinkingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Text("検索しています" + String(repeating: ".", count: dotCount + 1))
                .font(.system(size: 11))
                .foregroundStyle(buttonShadow)
            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}
