import SwiftUI

struct DolphinView: View {
    let onTap: @MainActor () -> Void
    var animationState: DolphinAnimationState = .idle

    @State private var bobOffset: CGFloat = 0
    @State private var shadowOpacity: Double = 0.2

    /// Map animation state to the corresponding GIF resource name
    private var gifName: String {
        switch animationState {
        case .idle:     return "kairu_idle"
        case .thinking: return "kairu_thinking"
        case .talking:  return "kairu_talking"
        case .greeting: return "kairu_idle" // reuse idle with bounce effect
        }
    }

    var body: some View {
        ZStack {
            // Drop shadow beneath dolphin (Office 97/XP style)
            Ellipse()
                .fill(Color.black.opacity(shadowOpacity))
                .frame(width: 70, height: 16)
                .blur(radius: 4)
                .offset(y: 54 - bobOffset * 0.2)

            // Animated GIF of the real Kairu character
            AnimatedGIFView(gifName: gifName)
                .frame(width: 124, height: 93)
                .offset(y: bobOffset)
        }
        .frame(width: 140, height: 128)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onChange(of: animationState) { _, newState in
            applyMotion(for: newState)
        }
        .onAppear {
            applyMotion(for: .idle)
        }
    }

    private func applyMotion(for state: DolphinAnimationState) {
        switch state {
        case .idle:
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bobOffset = -5
                shadowOpacity = 0.15
            }

        case .thinking:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bobOffset = -8
                shadowOpacity = 0.25
            }

        case .talking:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bobOffset = -3
                shadowOpacity = 0.2
            }

        case .greeting:
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 8)) {
                bobOffset = -20
                shadowOpacity = 0.1
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.spring(duration: 0.8)) {
                    bobOffset = 0
                    shadowOpacity = 0.2
                }
            }
        }
    }
}
