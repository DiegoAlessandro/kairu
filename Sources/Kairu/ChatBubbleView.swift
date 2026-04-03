import SwiftUI

// Windows classic UI colors
private let balloonBg = Color(red: 1.0, green: 1.0, blue: 0.88)
private let balloonBorder = Color(red: 0.0, green: 0.0, blue: 0.0)
private let buttonFace = Color(red: 0.85, green: 0.83, blue: 0.78)
private let buttonHighlight = Color.white
private let buttonShadow = Color(red: 0.5, green: 0.5, blue: 0.5)
private let inputBg = Color.white
private let headerText = Color.black

struct ChatBubbleView: View {
    @ObservedObject var viewModel: ChatViewModel
    let onClose: @MainActor () -> Void

    @AppStorage("bubbleWidth") private var bubbleWidth: Double = 300
    @AppStorage("bubbleHeight") private var bubbleHeight: Double = 400
    @AppStorage("draftText") private var draftText: String = ""
    @State private var inputText = ""
    @State private var inputHistory: [String] = []
    @State private var historyIndex: Int = -1
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // === Title bar ===
            HStack(spacing: 4) {
                Text("何について調べますか？")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(headerText)

                // Connection mode indicator
                Text(connectionLabel)
                    .font(.system(size: 8))
                    .foregroundStyle(buttonShadow)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(buttonFace.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Spacer()

                Button(action: onClose) {
                    Text("✕")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 16, height: 16)
                        .background(ClassicButton())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            // === Messages area ===
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        // Suggested questions when empty
                        if viewModel.messages.count <= 1 && !viewModel.isThinking {
                            SuggestedQuestions { question in
                                inputText = question
                                sendMessage()
                            }
                        }

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
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isThinking) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            .background(balloonBg)
            .overlay(Rectangle().stroke(buttonShadow, lineWidth: 1))
            .padding(.horizontal, 8)

            Spacer().frame(height: 6)

            // === Input field ===
            HStack(spacing: 0) {
                TextField("お前を消す方法", text: $inputText)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                    .onKeyPress(.upArrow) { navigateHistory(direction: -1); return .handled }
                    .onKeyPress(.downArrow) { navigateHistory(direction: 1); return .handled }
                    .onKeyPress(.escape) { onClose(); return .handled }
                    .padding(4)
                    .background(inputBg)
                    .overlay(ClassicInsetBorder())
                    .onChange(of: inputText) { _, new in draftText = new }
            }
            .padding(.horizontal, 8)

            Spacer().frame(height: 8)

            // === Bottom buttons ===
            HStack(spacing: 6) {
                // Connection status + reconnect
                if !viewModel.isConnected {
                    HStack(spacing: 3) {
                        Circle().fill(.orange).frame(width: 5, height: 5)
                        Button(action: { viewModel.checkConnection() }) {
                            Text("再接続")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Copy last response
                if let lastAI = viewModel.messages.last(where: { !$0.isUser }) {
                    Button(action: { copyToClipboard(lastAI.text) }) {
                        Text("コピー")
                            .font(.system(size: 11))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ClassicButton())
                    }
                    .buttonStyle(.plain)
                }

                // Retry button (when last message was error or timeout)
                if let lastUser = viewModel.lastUserMessage, !viewModel.isSending {
                    Button(action: { viewModel.send(lastUser) }) {
                        Text("再送")
                            .font(.system(size: 11))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ClassicButton())
                    }
                    .buttonStyle(.plain)
                }

                // Clear
                Button(action: {
                    viewModel.clearHistory()
                    inputHistory = []
                    historyIndex = -1
                }) {
                    Text("クリア")
                        .font(.system(size: 11))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ClassicButton())
                }
                .buttonStyle(.plain)

                // Send
                Button(action: sendMessage) {
                    Text("検索")
                        .font(.system(size: 11))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? buttonShadow : .black
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ClassicButton())
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: CGFloat(bubbleWidth), height: CGFloat(bubbleHeight))
        .frame(minWidth: 220, minHeight: 250)
        .background(balloonBg)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(balloonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.25), radius: 2, x: 2, y: 2)
        // Resize handle at bottom-right
        .overlay(alignment: .bottomTrailing) {
            ResizeHandle { delta in
                bubbleWidth = max(220, bubbleWidth + delta.width)
                bubbleHeight = max(250, bubbleHeight + delta.height)
                resizeParentWindow()
            }
        }
        .onAppear {
            isInputFocused = true
            inputText = draftText
            viewModel.checkConnection()
        }
    }

    // MARK: - Connection label

    private var connectionLabel: String {
        let cfg = KairuConfig.shared
        switch cfg.connectionMode {
        case .docker: return cfg.agentName + " / docker"
        case .native: return cfg.agentName + " / native"
        case .ssh:    return cfg.agentName + " / ssh"
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputHistory.append(text)
        historyIndex = inputHistory.count
        inputText = ""
        draftText = ""
        viewModel.send(text)
    }

    private func navigateHistory(direction: Int) {
        guard !inputHistory.isEmpty else { return }
        let newIndex = historyIndex + direction
        if newIndex >= 0 && newIndex < inputHistory.count {
            historyIndex = newIndex
            inputText = inputHistory[newIndex]
        } else if newIndex >= inputHistory.count {
            historyIndex = inputHistory.count
            inputText = ""
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if viewModel.isThinking {
            withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
        } else if let lastId = viewModel.messages.last?.id {
            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
        }
    }

    private func resizeParentWindow() {
        // Find the NSWindow hosting this SwiftUI view
        guard let window = NSApp.windows.first(where: { $0 is ChatBubblePanel }) else { return }
        var frame = window.frame
        let oldHeight = frame.height
        frame.size.width = CGFloat(bubbleWidth)
        frame.size.height = CGFloat(bubbleHeight)
        // Keep top-left anchored (macOS origin is bottom-left)
        frame.origin.y -= (frame.height - oldHeight)
        window.setFrame(frame, display: true)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Suggested Questions

struct SuggestedQuestions: View {
    let onSelect: (String) -> Void

    private let suggestions = [
        "このエラーを要約して",
        "次にやることを整理して",
        "@dev リポジトリを最新化して",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(suggestions, id: \.self) { q in
                Button(action: { onSelect(q) }) {
                    HStack(spacing: 4) {
                        Text("▸")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                        Text(q)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Resize Handle

struct ResizeHandle: View {
    let onDrag: (CGSize) -> Void
    @State private var lastDrag: CGSize = .zero

    var body: some View {
        Text("◢")
            .font(.system(size: 10))
            .foregroundStyle(buttonShadow)
            .frame(width: 14, height: 14)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = CGSize(
                            width: value.translation.width - lastDrag.width,
                            height: value.translation.height - lastDrag.height
                        )
                        onDrag(delta)
                        lastDrag = value.translation
                    }
                    .onEnded { _ in lastDrag = .zero }
            )
    }
}

// MARK: - Windows Classic UI Components

struct ClassicButton: View {
    var body: some View {
        ZStack {
            buttonFace
            VStack(spacing: 0) { Rectangle().fill(buttonHighlight).frame(height: 1); Spacer() }
            HStack(spacing: 0) { Rectangle().fill(buttonHighlight).frame(width: 1); Spacer() }
            VStack(spacing: 0) { Spacer(); Rectangle().fill(buttonShadow).frame(height: 1) }
            HStack(spacing: 0) { Spacer(); Rectangle().fill(buttonShadow).frame(width: 1) }
        }
    }
}

struct ClassicInsetBorder: View {
    var body: some View {
        ZStack {
            VStack(spacing: 0) { Rectangle().fill(buttonShadow).frame(height: 1); Spacer() }
            HStack(spacing: 0) { Rectangle().fill(buttonShadow).frame(width: 1); Spacer() }
            VStack(spacing: 0) { Spacer(); Rectangle().fill(buttonHighlight).frame(height: 1) }
            HStack(spacing: 0) { Spacer(); Rectangle().fill(buttonHighlight).frame(width: 1) }
        }
    }
}

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

struct MarkdownText: View {
    let source: String
    init(_ source: String) { self.source = source }

    var body: some View {
        Text(rendered)
            .font(.system(size: 12))
            .foregroundColor(.black)
            .tint(Color(red: 0.1, green: 0.3, blue: 0.7))
    }

    private var rendered: AttributedString {
        if let md = try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) { return md }
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
        .onReceive(timer) { _ in dotCount = (dotCount + 1) % 3 }
    }
}
