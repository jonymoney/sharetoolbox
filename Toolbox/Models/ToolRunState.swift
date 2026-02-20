import Foundation
import Observation

@Observable
final class ToolRunState {
    var outputLines: [OutputLine] = []
    var isRunning = false
    var exitCode: Int32?

    struct OutputLine: Identifiable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    func reset() {
        outputLines = []
        isRunning = false
        exitCode = nil
    }

    func appendOutput(_ text: String, isError: Bool = false) {
        let lines = text.components(separatedBy: "\n")
        for line in lines where !line.isEmpty {
            outputLines.append(OutputLine(text: line, isError: isError))
        }
    }
}
