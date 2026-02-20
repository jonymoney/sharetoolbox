import SwiftUI

struct ToolPickerView: View {
    let tools: [Tool]
    var onToolSelected: (Tool) -> Void
    var onCreateWithAI: () -> Void
    var onAddFromFolder: () -> Void
    var onAddFromGitHub: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(tools) { tool in
                    Button {
                        onToolSelected(tool)
                    } label: {
                        toolCard(icon: tool.icon, name: tool.name, description: tool.description)
                    }
                    .buttonStyle(.plain)
                }

                // Add Tool card
                Menu {
                    Button { onCreateWithAI() } label: {
                        Label("Create with AI", systemImage: "wand.and.stars")
                    }
                    Button { onAddFromFolder() } label: {
                        Label("Add from Folder", systemImage: "folder.badge.plus")
                    }
                    Button { onAddFromGitHub() } label: {
                        Label("Add from GitHub", systemImage: "arrow.down.circle")
                    }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text("Add Tool")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(.quaternary)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toolCard(icon: String, name: String, description: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
            Text(name)
                .font(.headline)
                .lineLimit(1)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}
