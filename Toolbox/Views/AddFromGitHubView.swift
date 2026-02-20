import SwiftUI

struct AddFromGitHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var repoURL = ""
    @State private var runState = ToolRunState()

    private let scriptPath = "/Users/jony.money/Documents/Dev/Explorations/Toolbox/create-tool.sh"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Add from GitHub")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            Text("Provide a GitHub repo URL. It will be cloned and AI will generate the config.")
                .foregroundStyle(.secondary)

            // URL field
            VStack(alignment: .leading, spacing: 4) {
                Text("Repository URL")
                    .fontWeight(.medium)
                TextField("https://github.com/user/repo", text: $repoURL)
                    .textFieldStyle(.roundedBorder)
            }

            // Clone & Analyze button
            HStack {
                Button(action: cloneAndAnalyze) {
                    Label(runState.isRunning ? "Cloning..." : "Clone & Analyze", systemImage: "sparkles")
                        .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(runState.isRunning || repoURL.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)

                if runState.isRunning || !runState.outputLines.isEmpty {
                    Button("Clear") { runState.reset() }
                        .controlSize(.large)
                }
            }

            // Output
            if runState.isRunning || !runState.outputLines.isEmpty || runState.exitCode != nil {
                OutputView(
                    lines: runState.outputLines,
                    isRunning: runState.isRunning,
                    exitCode: runState.exitCode
                )
            }
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 400)
    }

    private func cloneAndAnalyze() {
        CommandRunner.runScript(
            arguments: [scriptPath, "github", repoURL],
            state: runState
        )
    }
}
