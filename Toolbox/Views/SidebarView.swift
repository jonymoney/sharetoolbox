import SwiftUI

struct SidebarView: View {
    let tools: [Tool]
    @Binding var selection: Tool?
    @Binding var toolToDelete: Tool?

    var body: some View {
        List(tools, selection: $selection) { tool in
            HStack(spacing: 10) {
                Image(systemName: tool.icon)
                    .frame(width: 24)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(tool.name)
                        .fontWeight(.medium)
                    Text(tool.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
            .tag(tool)
            .contextMenu {
                Button(role: .destructive) {
                    toolToDelete = tool
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .listStyle(.sidebar)
    }
}
