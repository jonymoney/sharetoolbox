import Foundation
import Observation

@Observable
final class ToolManager {
    var tools: [Tool] = []

    private let toolsDirectoryURL: URL
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        toolsDirectoryURL = home.appendingPathComponent(".toolbox/tools")
        ensureDirectoryExists()
        loadTools()
        startWatching()
    }

    deinit {
        stopWatching()
    }

    private func ensureDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: toolsDirectoryURL.path) {
            try? fm.createDirectory(at: toolsDirectoryURL, withIntermediateDirectories: true)
        }
    }

    func loadTools() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: toolsDirectoryURL, includingPropertiesForKeys: nil) else {
            tools = []
            return
        }

        let jsonFiles = files.filter { $0.pathExtension == "json" }
        var loaded: [Tool] = []

        for file in jsonFiles {
            guard let data = try? Data(contentsOf: file) else { continue }
            let decoder = JSONDecoder()
            if let tool = try? decoder.decode(Tool.self, from: data) {
                loaded.append(tool)
            }
        }

        tools = loaded.sorted { $0.name < $1.name }
    }

    private func startWatching() {
        fileDescriptor = open(toolsDirectoryURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.loadTools()
        }

        source.setCancelHandler { [weak self] in
            guard let fd = self?.fileDescriptor, fd >= 0 else { return }
            close(fd)
            self?.fileDescriptor = -1
        }

        source.resume()
        dispatchSource = source
    }

    private func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    // MARK: - Delete

    private var scriptsDirectoryPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".toolbox/scripts")
            .path
    }

    func isManagedTool(_ tool: Tool) -> Bool {
        tool.command.hasPrefix(scriptsDirectoryPath)
    }

    func configFileURL(for tool: Tool) -> URL? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: toolsDirectoryURL, includingPropertiesForKeys: nil) else {
            return nil
        }

        let decoder = JSONDecoder()
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let decoded = try? decoder.decode(Tool.self, from: data),
                  decoded.name == tool.name else { continue }
            return file
        }
        return nil
    }

    func deleteTool(tool: Tool, deleteCommand: Bool) {
        let fm = FileManager.default

        // Delete config file
        if let configURL = configFileURL(for: tool) {
            try? fm.removeItem(at: configURL)
        }

        // Optionally delete the command / repo
        if deleteCommand {
            if isManagedTool(tool) {
                // Managed tool — delete the repo directory (parent of the script)
                let scriptURL = URL(fileURLWithPath: tool.command)
                let repoDir = scriptURL.deletingLastPathComponent()
                try? fm.removeItem(at: repoDir)
            } else {
                // External tool — delete the executable file
                try? fm.removeItem(atPath: tool.command)
            }
        }
    }
}
