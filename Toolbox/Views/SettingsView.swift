import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            EnvironmentSettingsTab()
                .tabItem {
                    Label("Environment", systemImage: "key")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}

// MARK: - Environment Tab

struct EnvironmentSettingsTab: View {
    @Environment(ToolManager.self) private var toolManager
    @State private var storedKeys: [(tool: String, key: String)] = []
    @State private var editingKey: String?
    @State private var editValue: String = ""

    private var toolsWithEnv: [Tool] {
        toolManager.tools.filter { $0.environment != nil && !$0.environment!.isEmpty }
    }

    var body: some View {
        Group {
            if toolsWithEnv.isEmpty {
                ContentUnavailableView {
                    Label("No Environment Variables", systemImage: "key")
                } description: {
                    Text("Tools with environment variables defined in their config will appear here.")
                }
            } else {
                List {
                    ForEach(toolsWithEnv) { tool in
                        Section(tool.name) {
                            ForEach(tool.environment ?? []) { envVar in
                                envVarRow(tool: tool, envVar: envVar)
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadStoredKeys() }
    }

    @ViewBuilder
    private func envVarRow(tool: Tool, envVar: EnvironmentVar) -> some View {
        let compositeKey = "\(tool.name).\(envVar.name)"
        let isStored = storedKeys.contains { $0.tool == tool.name && $0.key == envVar.name }
        let isEditing = editingKey == compositeKey

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(envVar.label)
                    .fontWeight(.medium)
                Text(envVar.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }

            Spacer()

            if isEditing {
                SecureField("Enter value", text: $editValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onSubmit { commitEdit(tool: tool, envVar: envVar) }

                Button("Save") { commitEdit(tool: tool, envVar: envVar) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button("Cancel") { editingKey = nil }
                    .controlSize(.small)
            } else {
                Text(isStored ? "••••••••" : "Not set")
                    .foregroundStyle(isStored ? .primary : .secondary)

                Button {
                    editValue = ""
                    editingKey = compositeKey
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Edit")

                if isStored {
                    Button {
                        KeychainHelper.delete(tool: tool.name, key: envVar.name)
                        loadStoredKeys()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
            }
        }
    }

    private func commitEdit(tool: Tool, envVar: EnvironmentVar) {
        if editValue.isEmpty {
            KeychainHelper.delete(tool: tool.name, key: envVar.name)
        } else {
            KeychainHelper.save(tool: tool.name, key: envVar.name, value: editValue)
        }
        editValue = ""
        editingKey = nil
        loadStoredKeys()
    }

    private func loadStoredKeys() {
        storedKeys = KeychainHelper.allStoredKeys()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Toolbox")
                .font(.title.bold())

            Text("Wrap CLI tools with a native macOS GUI.")
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 12) {
                Link(destination: URL(string: "https://sharetoolbox.app")!) {
                    Label("sharetoolbox.app", systemImage: "globe")
                }

                Link(destination: URL(string: "https://github.com/jonymoney")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Link(destination: URL(string: "https://www.instagram.com/jony.money")!) {
                    Label("Instagram", systemImage: "camera")
                }
            }
            .font(.body)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
