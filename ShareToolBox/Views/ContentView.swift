import SwiftUI

struct ContentView: View {
    @Binding var selectedSessionID: UUID?
    @Environment(ToolManager.self) private var toolManager
    @Environment(SessionManager.self) private var sessionManager
    @State private var showingCreateWithAI = false
    @State private var showingAddFromFolder = false
    @State private var showingAddFromGitHub = false
    @State private var sessionToDelete: Session?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSessionID, sessionToDelete: $sessionToDelete)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            if let selectedSessionID {
                SessionDetailView(sessionID: selectedSessionID)
                    .id(selectedSessionID)
            } else {
                ToolPickerView(
                    tools: toolManager.tools,
                    onToolSelected: { tool in
                        let session = sessionManager.createSession(from: tool)
                        selectedSessionID = session.id
                    },
                    onCreateWithAI: { showingCreateWithAI = true },
                    onAddFromFolder: { showingAddFromFolder = true },
                    onAddFromGitHub: { showingAddFromGitHub = true }
                )
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
        .alert(
            "Delete session?",
            isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    if selectedSessionID == session.id {
                        selectedSessionID = nil
                    }
                    sessionManager.delete(session)
                }
                sessionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: {
            if let session = sessionToDelete {
                Text("This will permanently delete the \"\(session.toolName)\" session and its output.")
            }
        }
    }
}
