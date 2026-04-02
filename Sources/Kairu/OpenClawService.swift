import Foundation

/// Snapshot of config values safe to use off-MainActor
struct OpenClawConnectionConfig: Sendable {
    let containerName: String
    let agentName: String
    let timeoutSeconds: Int

    @MainActor
    static var current: OpenClawConnectionConfig {
        let cfg = KairuConfig.shared
        return OpenClawConnectionConfig(
            containerName: cfg.containerName,
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

    /// Check if OpenClaw container is running and healthy
    func checkHealth(config: OpenClawConnectionConfig) async -> ConnectionStatus {
        do {
            let output = try await runProcess(
                arguments: ["docker", "inspect", "--format", "{{.State.Health.Status}}", config.containerName],
                timeoutSeconds: 5
            )
            return output.trimmingCharacters(in: .whitespacesAndNewlines) == "healthy"
                ? .connected : .disconnected
        } catch {
            return .error(error.localizedDescription)
        }
    }

    /// Send a message to OpenClaw via docker exec.
    /// Uses a temp file inside the container to avoid exposing user input in process args.
    func sendMessage(_ text: String, config: OpenClawConnectionConfig) async -> String {
        do {
            // Write message to a temp file inside the container via stdin,
            // then read it with -m "$(cat ...)" to keep user input out of `ps`
            let tmpPath = "/tmp/kairu_msg_\(UUID().uuidString.prefix(8))"

            // Step 1: Write message to temp file via stdin (safe, no escaping)
            _ = try await runProcess(
                arguments: [
                    "docker", "exec", "-i", config.containerName,
                    "sh", "-c", "cat > \(tmpPath)"
                ],
                stdinData: text.data(using: .utf8),
                timeoutSeconds: 5
            )

            // Step 2: Run openclaw reading from the temp file
            let output = try await runProcess(
                arguments: [
                    "docker", "exec", config.containerName,
                    "sh", "-c",
                    "openclaw agent --agent \(config.agentName) --local -m \"$(cat \(tmpPath))\" ; rm -f \(tmpPath)"
                ],
                timeoutSeconds: config.timeoutSeconds
            )

            let cleaned = cleanResponse(output)
            return cleaned.isEmpty ? "応答を取得できませんでした。" : cleaned
        } catch let error as OpenClawError {
            return error.userMessage
        } catch {
            return "接続エラー: \(error.localizedDescription)\nOpenClaw コンテナが起動しているか確認してください。"
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

    /// Run a process with async I/O, stdin support, and timeout
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

        // Use stdin pipe if we have data to send
        if let stdinData {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            try process.run()
            // Write message via stdin then close (safe: no shell escaping needed)
            stdinPipe.fileHandleForWriting.write(stdinData)
            stdinPipe.fileHandleForWriting.closeFile()
        } else {
            try process.run()
        }

        // Read stdout/stderr concurrently to prevent pipe deadlock
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
                // Once process is done and both pipes are read, cancel timeout
                if finished && !stdoutData.isEmpty || finished && !stderrData.isEmpty {
                    group.cancelAll()
                    break
                }
            }

            let stdout = String(data: stdoutData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if !stdout.isEmpty {
                return stdout
            }
            if stderr.contains("token") || stderr.contains("auth") || stderr.contains("OAuth") {
                throw OpenClawError.authExpired
            }
            if !stderr.isEmpty {
                throw OpenClawError.processError(stderr)
            }
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
