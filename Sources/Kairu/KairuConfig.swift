import Foundation

/// How Kairu connects to OpenClaw
enum ConnectionMode: String, CaseIterable, Sendable {
    case docker  = "docker"    // docker exec -i <container> openclaw agent ...
    case native  = "native"    // openclaw agent ... (locally installed)
    case ssh     = "ssh"       // ssh <host> openclaw agent ...

    var label: String {
        switch self {
        case .docker: return "Docker"
        case .native: return "ネイティブ"
        case .ssh:    return "SSH (リモート)"
        }
    }
}

/// Centralized configuration backed by UserDefaults.
@MainActor
final class KairuConfig: ObservableObject {
    static let shared = KairuConfig()

    private let defaults = UserDefaults.standard

    // MARK: - Connection mode

    @Published var connectionMode: ConnectionMode {
        didSet { defaults.set(connectionMode.rawValue, forKey: "connectionMode") }
    }

    // MARK: - Docker mode settings

    @Published var containerName: String {
        didSet { defaults.set(containerName, forKey: "containerName") }
    }

    // MARK: - SSH mode settings

    @Published var sshHost: String {
        didSet { defaults.set(sshHost, forKey: "sshHost") }
    }

    // MARK: - Shared settings

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
        let modeRaw = defaults.string(forKey: "connectionMode") ?? "docker"
        self.connectionMode = ConnectionMode(rawValue: modeRaw) ?? .docker
        self.containerName = defaults.string(forKey: "containerName") ?? "openclaw-parenting-ai"
        self.sshHost = defaults.string(forKey: "sshHost") ?? "pi@openclaw-pi"
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
