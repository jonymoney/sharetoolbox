import SwiftUI

struct ToolDetailView: View {
    let tool: Tool
    @State private var argumentValues: [String: String] = [:]
    @State private var flagValues: [String: Bool] = [:]
    @State private var envValues: [String: String] = [:]
    @State private var runState = ToolRunState()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: tool.icon)
                    .font(.title)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(tool.name)
                        .font(.title2.bold())
                    Text(tool.description)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // Form area (scrollable if needed, takes only the space it needs)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Arguments
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
                                            value: binding(for: arg)
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
                                        Toggle(flag.label, isOn: flagBinding(for: flag))
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
                                            SecureField(envVar.name, text: envBinding(for: envVar))
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

                    // Run button
                    HStack {
                        Button(action: runTool) {
                            Label(runState.isRunning ? "Running..." : "Run", systemImage: "play.fill")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(runState.isRunning || !allRequiredFieldsFilled)
                        .keyboardShortcut(.return, modifiers: .command)

                        if runState.isRunning || !runState.outputLines.isEmpty {
                            Button("Clear") {
                                runState.reset()
                            }
                            .controlSize(.large)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .layoutPriority(0)

            // Output box — fixed to the bottom, always visible once running
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
        .onAppear { initializeDefaults() }
        .onChange(of: tool) { initializeDefaults() }
    }

    private var allRequiredFieldsFilled: Bool {
        for arg in tool.arguments where arg.required {
            let val = argumentValues[arg.name] ?? ""
            if val.isEmpty { return false }
        }
        return true
    }

    private func initializeDefaults() {
        argumentValues = [:]
        flagValues = [:]
        envValues = [:]
        for arg in tool.arguments {
            argumentValues[arg.name] = arg.default ?? ""
        }
        for flag in tool.flags {
            flagValues[flag.name] = flag.default?.boolValue ?? false
        }
        for envVar in tool.environment ?? [] {
            envValues[envVar.name] = KeychainHelper.read(tool: tool.name, key: envVar.name) ?? ""
        }
        runState.reset()
    }

    private func binding(for argument: Argument) -> Binding<String> {
        Binding(
            get: { argumentValues[argument.name] ?? "" },
            set: { argumentValues[argument.name] = $0 }
        )
    }

    private func flagBinding(for flag: Flag) -> Binding<Bool> {
        Binding(
            get: { flagValues[flag.name] ?? false },
            set: { flagValues[flag.name] = $0 }
        )
    }

    private func envBinding(for envVar: EnvironmentVar) -> Binding<String> {
        Binding(
            get: { envValues[envVar.name] ?? "" },
            set: { envValues[envVar.name] = $0 }
        )
    }

    private func saveEnvVar(_ envVar: EnvironmentVar) {
        let value = envValues[envVar.name] ?? ""
        if value.isEmpty {
            KeychainHelper.delete(tool: tool.name, key: envVar.name)
        } else {
            KeychainHelper.save(tool: tool.name, key: envVar.name, value: value)
        }
    }

    private func runTool() {
        // Save any pending env var values before running
        for envVar in tool.environment ?? [] {
            saveEnvVar(envVar)
        }
        CommandRunner.run(
            tool: tool,
            argumentValues: argumentValues,
            flagValues: flagValues,
            state: runState
        )
    }
}
