import SwiftUI

struct SidebarView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Binding var selection: UUID?
    @Binding var sessionToDelete: Session?

    var body: some View {
        List(selection: $selection) {
            ForEach(sessionManager.groupedSessions, id: \.group) { group in
                Section(group.group.rawValue) {
                    ForEach(group.sessions) { session in
                        SessionRowView(session: session, sessionManager: sessionManager)
                            .tag(session.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct SessionRowView: View {
    let session: Session
    let sessionManager: SessionManager

    private var runState: ToolRunState {
        sessionManager.runState(for: session.id)
    }

    var body: some View {
        HStack(spacing: 10) {
            if runState.isRunning {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 24)
            } else {
                Image(systemName: session.toolIcon)
                    .frame(width: 24)
                    .foregroundColor(.accentColor)
            }
            VStack(alignment: .leading) {
                Text(session.toolName)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if runState.isRunning, let started = runState.runStartedAt {
                    Text(started, style: .timer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(session.createdAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !runState.isRunning, let code = runState.exitCode {
                Image(systemName: code == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(code == 0 ? .green : .red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
