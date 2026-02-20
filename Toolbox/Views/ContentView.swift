import SwiftUI

struct ContentView: View {
    @Environment(ToolManager.self) private var toolManager
    @State private var selectedTool: Tool?
    @State private var showingCreateWithAI = false
    @State private var showingAddFromFolder = false
    @State private var showingAddFromGitHub = false
    @State private var toolToDelete: Tool?

    var body: some View {
        NavigationSplitView {
            SidebarView(tools: toolManager.tools, selection: $selectedTool, toolToDelete: $toolToDelete)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
                .toolbar {
                    ToolbarItem {
                        Menu {
                            Button { showingCreateWithAI = true } label: {
                                Label("Create with AI", systemImage: "wand.and.stars")
                            }
                            Button { showingAddFromFolder = true } label: {
                                Label("Add from Folder", systemImage: "folder.badge.plus")
                            }
                            Button { showingAddFromGitHub = true } label: {
                                Label("Add from GitHub", systemImage: "arrow.down.circle")
                            }
                        } label: {
                            Label("Add Tool", systemImage: "plus")
                        }
                        .help("Add a new tool")
                    }
                }
                .sheet(isPresented: $showingCreateWithAI) {
                    CreateToolView()
                }
                .sheet(isPresented: $showingAddFromFolder) {
                    AddFromFolderView()
                }
                .sheet(isPresented: $showingAddFromGitHub) {
                    AddFromGitHubView()
                }
        } detail: {
            if let tool = selectedTool {
                ToolDetailView(tool: tool)
                    .id(tool.id)
            } else {
                ContentUnavailableView {
                    Label("Select a Tool", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("Choose a tool from the sidebar to get started.")
                } actions: {
                    if toolManager.tools.isEmpty {
                        Text("Add JSON config files to ~/.toolbox/tools/")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .alert(
            "Delete \(toolToDelete?.name ?? "")?",
            isPresented: Binding(
                get: { toolToDelete != nil },
                set: { if !$0 { toolToDelete = nil } }
            )
        ) {
            if let tool = toolToDelete {
                if toolManager.isManagedTool(tool) {
                    Button("Delete", role: .destructive) {
                        deleteTool(tool, deleteCommand: true)
                    }
                } else {
                    Button("Remove Reference") {
                        deleteTool(tool, deleteCommand: false)
                    }
                    Button("Delete All", role: .destructive) {
                        deleteTool(tool, deleteCommand: true)
                    }
                }
                Button("Cancel", role: .cancel) {
                    toolToDelete = nil
                }
            }
        } message: {
            if let tool = toolToDelete {
                if toolManager.isManagedTool(tool) {
                    Text("This will delete the tool config and its cloned repository.")
                } else {
                    Text("Delete just the Toolbox reference, or also delete the file at \(tool.command)?")
                }
            }
        }
    }

    private func deleteTool(_ tool: Tool, deleteCommand: Bool) {
        toolManager.deleteTool(tool: tool, deleteCommand: deleteCommand)
        if selectedTool == tool {
            selectedTool = nil
        }
        toolToDelete = nil
    }
}
