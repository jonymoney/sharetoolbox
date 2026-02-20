import Foundation

struct Session: Codable, Identifiable, Hashable {
    let id: UUID
    let toolName: String
    let toolIcon: String
    let toolDescription: String
    var argumentValues: [String: String]
    var flagValues: [String: Bool]
    var outputLines: [PersistedOutputLine]
    var exitCode: Int32?
    var createdAt: Date
    var lastRunAt: Date?

    struct PersistedOutputLine: Codable, Hashable {
        let text: String
        let isError: Bool
    }

    init(from tool: Tool) {
        self.id = UUID()
        self.toolName = tool.name
        self.toolIcon = tool.icon
        self.toolDescription = tool.description
        self.createdAt = Date()

        var args: [String: String] = [:]
        for arg in tool.arguments {
            args[arg.name] = arg.default ?? ""
        }
        self.argumentValues = args

        var flags: [String: Bool] = [:]
        for flag in tool.flags {
            flags[flag.name] = flag.default?.boolValue ?? false
        }
        self.flagValues = flags

        self.outputLines = []
        self.exitCode = nil
        self.lastRunAt = nil
    }
}
