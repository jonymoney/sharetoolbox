import SwiftUI

struct ArgumentFieldView: View {
    let argument: Argument
    @Binding var value: String

    var body: some View {
        switch argument.type {
        case .string:
            TextField(argument.placeholder ?? "", text: $value)
                .textFieldStyle(.roundedBorder)

        case .directory:
            HStack {
                TextField(argument.placeholder ?? "Select directory...", text: $value)
                    .textFieldStyle(.roundedBorder)
                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        value = url.path
                    }
                }
            }

        case .file:
            HStack {
                TextField(argument.placeholder ?? "Select file...", text: $value)
                    .textFieldStyle(.roundedBorder)
                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        value = url.path
                    }
                }
            }

        case .bool:
            Toggle(isOn: Binding(
                get: { value == "true" },
                set: { value = $0 ? "true" : "false" }
            )) {
                EmptyView()
            }
        }
    }
}
