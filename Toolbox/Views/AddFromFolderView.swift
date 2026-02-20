import SwiftUI

struct AddFromFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var folderPath = ""
    @State private var runState = ToolRunState()

    private let scriptPath = "/Users/jony.money/Documents/Dev/Explorations/Toolbox/create-tool.sh"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "folder.badge.plus")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Add from Folder")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            Text("Select a folder containing a script or tool. AI will analyze it and generate the config.")
                .foregroundStyle(.secondary)

            // Folder field
            VStack(alignment: .leading, spacing: 4) {
                Text("Folder Path")
                    .fontWeight(.medium)
                HStack {
                    TextField("No folder selected", text: $folderPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            folderPath = url.path
                        }
                    }
                }
            }

            // Analyze button
            HStack {
                Button(action: analyze) {
                    Label(runState.isRunning ? "Analyzing..." : "Analyze", systemImage: "sparkles")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(runState.isRunning || folderPath.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func analyze() {
        CommandRunner.runScript(
            arguments: [scriptPath, "folder", folderPath],
            state: runState
        )
    }
}
