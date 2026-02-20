import Foundation
import Observation

@Observable
final class SessionManager {
    var sessions: [Session] = []
    private var runStates: [UUID: ToolRunState] = [:]

    private let sessionsDirectoryURL: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        sessionsDirectoryURL = home.appendingPathComponent(".sharetoolbox/sessions")
        ensureDirectoryExists()
        loadSessions()
    }

    // MARK: - Directory

    private func ensureDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: sessionsDirectoryURL.path) {
            try? fm.createDirectory(at: sessionsDirectoryURL, withIntermediateDirectories: true)
        }
    }

    // MARK: - Load

    func loadSessions() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: sessionsDirectoryURL, includingPropertiesForKeys: nil) else {
            sessions = []
            return
        }

        let jsonFiles = files.filter { $0.pathExtension == "json" }
        var loaded: [Session] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in jsonFiles {
            guard let data = try? Data(contentsOf: file),
                  let session = try? decoder.decode(Session.self, from: data) else { continue }
            loaded.append(session)
        }

        sessions = loaded.sorted { $0.createdAt > $1.createdAt }

        // Populate run states from persisted data so sidebar shows completion status
        for session in sessions where session.exitCode != nil {
            let state = runState(for: session.id)
            if state.outputLines.isEmpty && !session.outputLines.isEmpty {
                state.loadPersistedOutput(session.outputLines, exitCode: session.exitCode)
            }
        }
    }

    // MARK: - CRUD

    @discardableResult
    func createSession(from tool: Tool) -> Session {
        let session = Session(from: tool)
        sessions.insert(session, at: 0)
        save(session)
        return session
    }

    func save(_ session: Session) {
        let url = sessionsDirectoryURL.appendingPathComponent("\(session.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        // Cap output at 5000 lines
        var capped = session
        if capped.outputLines.count > 5000 {
            let truncationNote = Session.PersistedOutputLine(
                text: "--- Output truncated (showing last 4999 of \(session.outputLines.count) lines) ---",
                isError: false
            )
            capped.outputLines = [truncationNote] + Array(session.outputLines.suffix(4999))
        }

        guard let data = try? encoder.encode(capped) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func update(_ session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        save(session)
    }

    func delete(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        runStates.removeValue(forKey: session.id)
        let url = sessionsDirectoryURL.appendingPathComponent("\(session.id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Run State

    func runState(for sessionID: UUID) -> ToolRunState {
        if let existing = runStates[sessionID] {
            return existing
        }
        let state = ToolRunState()
        runStates[sessionID] = state
        return state
    }

    // MARK: - Date Grouping

    enum SessionGroup: String, Hashable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case older = "Older"
    }

    var groupedSessions: [(group: SessionGroup, sessions: [Session])] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        var groups: [SessionGroup: [Session]] = [:]

        for session in sessions {
            let group: SessionGroup
            if session.createdAt >= startOfToday {
                group = .today
            } else if session.createdAt >= startOfYesterday {
                group = .yesterday
            } else if session.createdAt >= startOfWeek {
                group = .thisWeek
            } else {
                group = .older
            }
            groups[group, default: []].append(session)
        }

        let order: [SessionGroup] = [.today, .yesterday, .thisWeek, .older]
        return order.compactMap { group in
            guard let sessions = groups[group], !sessions.isEmpty else { return nil }
            return (group: group, sessions: sessions)
        }
    }
}
