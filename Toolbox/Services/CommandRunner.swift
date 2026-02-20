import Foundation

final class CommandRunner {
    static func run(
        tool: Tool,
        argumentValues: [String: String],
        flagValues: [String: Bool],
        state: ToolRunState
    ) {
        state.reset()
        state.isRunning = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.command)

        // Build arguments: flags first, then positional args
        var args: [String] = []

        for flag in tool.flags {
            let isEnabled = flagValues[flag.name] ?? flag.default?.boolValue ?? false
            if flag.type == .bool && isEnabled {
                args.append(flag.flag)
            }
        }

        for argument in tool.arguments {
            let value = argumentValues[argument.name] ?? argument.default ?? ""
            guard !value.isEmpty else { continue }

            switch argument.type {
            case .directory, .file:
                args.append((value as NSString).expandingTildeInPath)
            default:
                args.append(value)
            }
        }

        process.arguments = args

        // Augment PATH so Homebrew tools are found
        var env = ProcessInfo.processInfo.environment
        let currentPath = env["PATH"] ?? "/usr/bin:/bin"
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + currentPath

        // Inject environment variables from Keychain
        for envVar in tool.environment ?? [] {
            if let value = KeychainHelper.read(tool: tool.name, key: envVar.name) {
                env[envVar.name] = value
            }
        }

        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    state.appendOutput(str, isError: false)
                }
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    state.appendOutput(str, isError: true)
                }
            }
        }

        process.terminationHandler = { proc in
            // Clean up handlers
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil

            // Read any remaining data
            let remainingOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let remainingErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            DispatchQueue.main.async {
                if !remainingOut.isEmpty, let str = String(data: remainingOut, encoding: .utf8) {
                    state.appendOutput(str, isError: false)
                }
                if !remainingErr.isEmpty, let str = String(data: remainingErr, encoding: .utf8) {
                    state.appendOutput(str, isError: true)
                }
                state.exitCode = proc.terminationStatus
                state.isRunning = false
            }
        }

        do {
            try process.run()
        } catch {
            state.appendOutput("Failed to launch: \(error.localizedDescription)", isError: true)
            state.isRunning = false
        }
    }

    static func runScript(arguments: [String], state: ToolRunState, reset: Bool = true) {
        if reset {
            state.reset()
        } else {
            state.exitCode = nil
        }
        state.isRunning = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        let currentPath = env["PATH"] ?? "/usr/bin:/bin"
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + currentPath
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { state.appendOutput(str) }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { state.appendOutput(str, isError: true) }
        }

        process.terminationHandler = { proc in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            let remainingOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let remainingErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            DispatchQueue.main.async {
                if !remainingOut.isEmpty, let str = String(data: remainingOut, encoding: .utf8) {
                    state.appendOutput(str)
                }
                if !remainingErr.isEmpty, let str = String(data: remainingErr, encoding: .utf8) {
                    state.appendOutput(str, isError: true)
                }
                state.exitCode = proc.terminationStatus
                state.isRunning = false
            }
        }

        do {
            try process.run()
        } catch {
            state.appendOutput("Failed to launch: \(error.localizedDescription)", isError: true)
            state.isRunning = false
        }
    }
}
