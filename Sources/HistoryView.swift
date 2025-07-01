import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                if appState.sessionHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No history yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Your generated conversation starters will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(appState.sessionHistory) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRow(session: session)
                        }
                    }
                    .onDelete { indexSet in
                        appState.deleteSession(at: indexSet)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !appState.sessionHistory.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.timestamp, style: .date)
                .font(.headline)
            
            Text("\(session.openers.count) conversation starters")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let firstOpener = session.openers.first {
                Text(firstOpener.text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    let session: SessionData
    
    var body: some View {
        List(session.openers) { opener in
            VStack(alignment: .leading, spacing: 8) {
                Text(opener.text)
                    .font(.body)
                
                HStack {
                    Label(opener.style.rawValue, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if opener.confidence > 0.8 {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}