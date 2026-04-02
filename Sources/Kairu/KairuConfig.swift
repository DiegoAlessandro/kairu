import AppKit
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

    // MARK: - Global hotkey
    // Stored as modifier flags (int) + key code (int)
    // Default: Cmd+Shift+K

    @Published var hotkeyModifiers: Int {
        didSet { defaults.set(hotkeyModifiers, forKey: "hotkeyModifiers") }
    }

    @Published var hotkeyKeyCode: Int {
        didSet { defaults.set(hotkeyKeyCode, forKey: "hotkeyKeyCode") }
    }

    /// Human-readable hotkey description
    var hotkeyDescription: String {
        var parts: [String] = []
        let mods = NSEvent.ModifierFlags(rawValue: UInt(hotkeyModifiers))
        if mods.contains(.control) { parts.append("⌃") }
        if mods.contains(.option)  { parts.append("⌥") }
        if mods.contains(.shift)   { parts.append("⇧") }
        if mods.contains(.command) { parts.append("⌘") }
        parts.append(keyCodeToString(hotkeyKeyCode))
        return parts.joined()
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
        self.containerName = defaults.string(forKey: "containerName") ?? "openclaw"
        self.sshHost = defaults.string(forKey: "sshHost") ?? "user@localhost"
        self.agentName = defaults.string(forKey: "agentName") ?? "main"
        self.timeoutSeconds = defaults.integer(forKey: "timeoutSeconds").nonZero ?? 120
        // Default: Cmd+Shift+K (keyCode 40 = K)
        let storedMods = defaults.integer(forKey: "hotkeyModifiers")
        let storedKey = defaults.integer(forKey: "hotkeyKeyCode")
        self.hotkeyModifiers = storedMods != 0 ? storedMods
            : Int(NSEvent.ModifierFlags([.command, .shift]).rawValue)
        self.hotkeyKeyCode = storedKey != 0 ? storedKey : 40  // K
        self.dolphinX = defaults.double(forKey: "dolphinX")
        self.dolphinY = defaults.double(forKey: "dolphinY")
        self.hasStoredPosition = defaults.bool(forKey: "hasStoredPosition")
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

/// Convert a macOS virtual key code to a readable string
func keyCodeToString(_ keyCode: Int) -> String {
    let map: [Int: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
        38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
        36: "Return", 48: "Tab", 51: "Delete", 53: "Esc",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
        97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
        103: "F11", 111: "F12",
    ]
    return map[keyCode] ?? "Key\(keyCode)"
}
