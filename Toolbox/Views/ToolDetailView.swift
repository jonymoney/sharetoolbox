import SwiftUI

struct ToolDetailView: View {
    let tool: Tool
    @State private var argumentValues: [String: String] = [:]
    @State private var flagValues: [String: Bool] = [:]
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
        for arg in tool.arguments {
            argumentValues[arg.name] = arg.default ?? ""
        }
        for flag in tool.flags {
            flagValues[flag.name] = flag.default?.boolValue ?? false
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

    private func runTool() {
        CommandRunner.run(
            tool: tool,
            argumentValues: argumentValues,
            flagValues: flagValues,
            state: runState
        )
    }
}
