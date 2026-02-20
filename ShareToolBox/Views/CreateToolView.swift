import SwiftUI

struct CreateToolView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var followUp = ""
    @State private var runState = ToolRunState()
    @State private var hasRun = false

    private let scriptPath = "/Users/jony.money/Documents/Dev/Explorations/ShareToolBox/create-tool.sh"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Create Tool with AI")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            Text("Describe a CLI tool and Claude will generate the ShareToolBox config. Mention the script path so it can read it.")
                .foregroundStyle(.secondary)

            if !hasRun {
                // Description field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tool Description")
                        .fontWeight(.medium)
                    TextField(
                        "e.g. Add my script at ~/scripts/resize.sh — it takes an input image, output dir, and a --width flag",
                        text: $description,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                }

                // Run button
                Button(action: run) {
                    Label("Create", systemImage: "sparkles")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }

            // Output
            if hasRun {
                OutputView(
                    lines: runState.outputLines,
                    isRunning: runState.isRunning,
                    exitCode: runState.exitCode
                )

                // Follow-up input
                if !runState.isRunning {
                    HStack(spacing: 8) {
                        TextField("Reply to Claude...", text: $followUp, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                            .onSubmit { sendFollowUp() }
                        Button(action: sendFollowUp) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .disabled(followUp.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 400)
    }

    private func run() {
        hasRun = true
        CommandRunner.runScript(
            arguments: [scriptPath, "create", description],
            state: runState
        )
    }

    private func sendFollowUp() {
        let text = followUp.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        followUp = ""

        runState.appendOutput("> \(text)", isError: false)

        CommandRunner.runScript(
            arguments: [scriptPath, "continue", text],
            state: runState,
            reset: false
        )
    }
}
