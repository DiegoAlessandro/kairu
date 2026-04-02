import Foundation

/// Centralized configuration backed by UserDefaults.
/// All settings are editable from the Settings/Options UI.
@MainActor
final class KairuConfig: ObservableObject {
    static let shared = KairuConfig()

    private let defaults = UserDefaults.standard

    // MARK: - OpenClaw connection

    @Published var containerName: String {
        didSet { defaults.set(containerName, forKey: "containerName") }
    }

    @Published var agentName: String {
        didSet { defaults.set(agentName, forKey: "agentName") }
    }

    @Published var timeoutSeconds: Int {
        didSet { defaults.set(timeoutSeconds, forKey: "timeoutSeconds") }
    }

    // MARK: - Window position

    @Published var dolphinX: Double {
        didSet { defaults.set(dolphinX, forKey: "dolphinX") }
    }

    @Published var dolphinY: Double {
        didSet { defaults.set(dolphinY, forKey: "dolphinY") }
    }

    @Published var hasStoredPosition: Bool {
        didSet { defaults.set(hasStoredPosition, forKey: "hasStoredPosition") }
    }

    // MARK: - Init

    private init() {
        self.containerName = defaults.string(forKey: "containerName") ?? "openclaw-parenting-ai"
        self.agentName = defaults.string(forKey: "agentName") ?? "main"
        self.timeoutSeconds = defaults.integer(forKey: "timeoutSeconds").nonZero ?? 120
        self.dolphinX = defaults.double(forKey: "dolphinX")
        self.dolphinY = defaults.double(forKey: "dolphinY")
        self.hasStoredPosition = defaults.bool(forKey: "hasStoredPosition")
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
