import SwiftUI

@main
struct ToolboxApp: App {
    @State private var toolManager = ToolManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(toolManager)
                .frame(minWidth: 700, minHeight: 500)
        }
    }
}
