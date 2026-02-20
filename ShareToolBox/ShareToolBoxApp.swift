import SwiftUI

@main
struct ShareToolBoxApp: App {
    @State private var toolManager = ToolManager()
    @State private var sessionManager = SessionManager()
    @State private var selectedSessionID: UUID?

    var body: some Scene {
        WindowGroup {
            ContentView(selectedSessionID: $selectedSessionID)
                .environment(toolManager)
                .environment(sessionManager)
                .frame(minWidth: 700, minHeight: 500)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    selectedSessionID = nil
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(toolManager)
        }
    }
}
