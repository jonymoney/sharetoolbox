import SwiftUI

struct SessionDetailView: View {
    let sessionID: UUID
    @Environment(SessionManager.self) private var sessionManager
    @Environment(ToolManager.self) private var toolManager
    @State private var argumentValues: [String: String] = [:]
    @State private var flagValues: [String: Bool] = [:]
    @State private var envValues: [String: String] = [:]
    @State private var initialized = false

    private var session: Session? {
        sessionManager.sessions.first { $0.id == sessionID }
    }

    private var liveTool: Tool? {
        toolManager.tools.first { $0.name == session?.toolName }
    }

    private var runState: ToolRunState {
        sessionManager.runState(for: sessionID)
    }

    var body: some View {
        if let session {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: session.toolIcon)
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text(session.toolName)
                            .font(.title2.bold())
                        Text(session.toolDescription)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()

                Divider()

                // Form area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Arguments — use live tool if available for full metadata, fall back to session keys
                        if let tool = liveTool {
                            if !tool.arguments.isEmpty {
                                GroupBox("Arguments") {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(tool.arguments) { arg in
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 4) {
                                                    Text(arg.label)
                                                        .fontWeight(.medium)
                                                    if arg.required {
                                                        Text("*")
                                                            .foregroundStyle(.red)
                                                    }
                                                }
                                                ArgumentFieldView(
                                                    argument: arg,
                                                    value: argBinding(for: arg.name)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Flags
                            if !tool.flags.isEmpty {
                                GroupBox("Options") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(tool.flags) { flag in
                                            if flag.type == .bool {
                                                Toggle(flag.label, isOn: flagBinding(for: flag.name))
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Environment
                            if let envVars = tool.environment, !envVars.isEmpty {
                                GroupBox("Environment") {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(envVars) { envVar in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(envVar.label)
                                                    .fontWeight(.medium)
                                                HStack(spacing: 8) {
                                                    SecureField(envVar.name, text: envBinding(for: envVar.name))
                                                        .textFieldStyle(.roundedBorder)
                                                        .onSubmit {
                                                            saveEnvVar(envVar)
                                                        }
                                                    if let val = envValues[envVar.name], !val.isEmpty {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundStyle(.green)
                                                            .help("Stored in Keychain")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // Run button
                        HStack {
                            if liveTool != nil {
                                Button(action: runTool) {
                                    Label(runState.isRunning ? "Running..." : "Run", systemImage: "play.fill")
                                        .frame(minWidth: 100)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .disabled(runState.isRunning || !allRequiredFieldsFilled)
                                .keyboardShortcut(.return, modifiers: .command)
                            } else {
                                Label("Tool not found", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.secondary)
                            }

                            if runState.isRunning || !runState.outputLines.isEmpty {
                                Button("Clear") {
                                    runState.reset()
                                    saveSession()
                                }
                                .controlSize(.large)
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .layoutPriority(0)

                // Output
                if runState.isRunning || !runState.outputLines.isEmpty || runState.exitCode != nil {
                    Divider()
                    OutputView(
                        lines: runState.outputLines,
                        isRunning: runState.isRunning,
                        exitCode: runState.exitCode
                    )
                    .padding()
                    .frame(height: 250)
                    .layoutPriority(1)
                }
            }
            .onAppear { initializeFromSession(session) }
            .onDisappear { saveSession() }
            .onChange(of: runState.isRunning) { old, new in
                if old && !new {
                    saveSession()
                }
            }
        } else {
            ContentUnavailableView("Session Not Found", systemImage: "questionmark.circle")
        }
    }

    // MARK: - Initialization

    private func initializeFromSession(_ session: Session) {
        guard !initialized else { return }
        initialized = true

        argumentValues = session.argumentValues
        flagValues = session.flagValues

        // Load env from Keychain
        if let tool = liveTool {
            for envVar in tool.environment ?? [] {
                envValues[envVar.name] = KeychainHelper.read(tool: tool.name, key: envVar.name) ?? ""
            }
        }

        // If run state has no output but session has persisted output, load it
        let state = runState
        if state.outputLines.isEmpty && !session.outputLines.isEmpty {
            state.loadPersistedOutput(session.outputLines, exitCode: session.exitCode)
        }
    }

    // MARK: - Save

    private func saveSession() {
        guard var session = session else { return }
        session.argumentValues = argumentValues
        session.flagValues = flagValues

        let state = runState
        session.outputLines = state.outputLines.map {
            Session.PersistedOutputLine(text: $0.text, isError: $0.isError)
        }
        session.exitCode = state.exitCode
        if state.exitCode != nil && session.lastRunAt == nil {
            session.lastRunAt = Date()
        }

        sessionManager.update(session)
    }

    // MARK: - Bindings

    private func argBinding(for name: String) -> Binding<String> {
        Binding(
            get: { argumentValues[name] ?? "" },
            set: { argumentValues[name] = $0 }
        )
    }

    private func flagBinding(for name: String) -> Binding<Bool> {
        Binding(
            get: { flagValues[name] ?? false },
            set: { flagValues[name] = $0 }
        )
    }

    private func envBinding(for name: String) -> Binding<String> {
        Binding(
            get: { envValues[name] ?? "" },
            set: { envValues[name] = $0 }
        )
    }

    // MARK: - Validation

    private var allRequiredFieldsFilled: Bool {
        guard let tool = liveTool else { return false }
        for arg in tool.arguments where arg.required {
            let val = argumentValues[arg.name] ?? ""
            if val.isEmpty { return false }
        }
        return true
    }

    // MARK: - Actions

    private func saveEnvVar(_ envVar: EnvironmentVar) {
        guard let tool = liveTool else { return }
        let value = envValues[envVar.name] ?? ""
        if value.isEmpty {
            KeychainHelper.delete(tool: tool.name, key: envVar.name)
        } else {
            KeychainHelper.save(tool: tool.name, key: envVar.name, value: value)
        }
    }

    private func runTool() {
        guard let tool = liveTool else { return }
        // Save env vars before running
        for envVar in tool.environment ?? [] {
            saveEnvVar(envVar)
        }

        // Update lastRunAt
        if var session = session {
            session.lastRunAt = Date()
            sessionManager.update(session)
        }

        let state = runState
        CommandRunner.run(
            tool: tool,
            argumentValues: argumentValues,
            flagValues: flagValues,
            state: state
        )
    }
}
