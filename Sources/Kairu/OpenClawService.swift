import Foundation

/// Snapshot of config values safe to use off-MainActor
struct OpenClawConnectionConfig: Sendable {
    let mode: ConnectionMode
    let containerName: String
    let sshHost: String
    let agentName: String
    let timeoutSeconds: Int

    @MainActor
    static var current: OpenClawConnectionConfig {
        let cfg = KairuConfig.shared
        return OpenClawConnectionConfig(
            mode: cfg.connectionMode,
            containerName: cfg.containerName,
            sshHost: cfg.sshHost,
            agentName: cfg.agentName,
            timeoutSeconds: cfg.timeoutSeconds
        )
    }
}

actor OpenClawService {
    enum ConnectionStatus: Sendable, Equatable {
        case connected
        case disconnected
        case error(String)
    }

    /// Check if OpenClaw is reachable
    func checkHealth(config: OpenClawConnectionConfig) async -> ConnectionStatus {
        let args = buildCommand(config: config, subcommand: ["openclaw", "health"])
        do {
            let output = try await runProcess(arguments: args, timeoutSeconds: 5)
            let clean = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return clean.contains("ok") || clean.contains("healthy") || clean.contains("live")
                ? .connected : .disconnected
        } catch {
            return .error(error.localizedDescription)
        }
    }

    /// Send a message to OpenClaw via stdin pipe
    func sendMessage(_ text: String, config: OpenClawConnectionConfig) async -> String {
        // Build the openclaw agent command
        let ocArgs = ["openclaw", "agent", "--agent", config.agentName, "--local", "-m", text]
        let args = buildCommand(config: config, subcommand: ocArgs)

        do {
            let output = try await runProcess(
                arguments: args,
                timeoutSeconds: config.timeoutSeconds
            )
            let cleaned = cleanResponse(output)
            return cleaned.isEmpty ? "応答を取得できませんでした。" : cleaned
        } catch let error as OpenClawError {
            return error.userMessage
        } catch {
            return "接続エラー: \(error.localizedDescription)"
        }
    }

    // MARK: - Command builder

    /// Build the full command array based on connection mode
    private func buildCommand(config: OpenClawConnectionConfig, subcommand: [String]) -> [String] {
        switch config.mode {
        case .docker:
            // docker exec <container> <subcommand...>
            return ["docker", "exec", config.containerName] + subcommand
        case .native:
            // Run openclaw directly (assumes it's in PATH)
            return subcommand
        case .ssh:
            // ssh <host> <subcommand as single string>
            let escaped = subcommand.map { arg in
                arg.contains(" ") || arg.contains("'") ? "'\(arg.replacingOccurrences(of: "'", with: "'\\''"))'" : arg
            }.joined(separator: " ")
            return ["ssh", "-o", "ConnectTimeout=5", config.sshHost, escaped]
        }
    }

    // MARK: - Private

    private enum OpenClawError: Error {
        case authExpired
        case timeout
        case processError(String)

        var userMessage: String {
            switch self {
            case .authExpired:
                return "⚠️ OpenClaw の認証トークンが期限切れです。再認証してください。"
            case .timeout:
                return "⏱ タイムアウトしました。もう一度お試しください。"
            case .processError(let msg):
                return "エラー: \(String(msg.prefix(200)))"
            }
        }
    }

    /// Run a process with async I/O and timeout
    private func runProcess(
        arguments: [String],
        stdinData: Data? = nil,
        timeoutSeconds: Int
    ) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let stdinData {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            try process.run()
            stdinPipe.fileHandleForWriting.write(stdinData)
            stdinPipe.fileHandleForWriting.closeFile()
        } else {
            try process.run()
        }

        enum ReadResult: Sendable {
            case stdout(Data)
            case stderr(Data)
            case done
            case timedOut
        }

        return try await withThrowingTaskGroup(of: ReadResult.self) { group in
            group.addTask {
                .stdout(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
            }
            group.addTask {
                .stderr(stderrPipe.fileHandleForReading.readDataToEndOfFile())
            }
            group.addTask {
                process.waitUntilExit()
                return .done
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds) * 1_000_000_000)
                process.terminate()
                return .timedOut
            }

            var stdoutData = Data()
            var stderrData = Data()
            var finished = false

            for try await result in group {
                switch result {
                case .stdout(let data): stdoutData = data
                case .stderr(let data): stderrData = data
                case .done: finished = true
                case .timedOut: throw OpenClawError.timeout
                }
                if finished && (!stdoutData.isEmpty || !stderrData.isEmpty) {
                    group.cancelAll()
                    break
                }
            }

            let stdout = String(data: stdoutData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if !stdout.isEmpty { return stdout }
            if stderr.contains("token") || stderr.contains("auth") || stderr.contains("OAuth") {
                throw OpenClawError.authExpired
            }
            if !stderr.isEmpty { throw OpenClawError.processError(stderr) }
            return ""
        }
    }

    /// Filter out diagnostic lines from OpenClaw output
    private func cleanResponse(_ output: String) -> String {
        output.components(separatedBy: "\n")
            .filter { !$0.hasPrefix("[") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
