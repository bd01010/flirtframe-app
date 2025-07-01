import SwiftUI

struct OpenerResultView: View {
    let image: UIImage
    let result: AnalysisResult
    let onGenerateMore: () -> Void
    let onDismiss: () -> Void
    
    @State private var openers: [Opener] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Display the analyzed image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Generating conversation starters...")
                            .padding()
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // Display generated openers
                        ForEach(openers, id: \.id) { opener in
                            OpenerCard(opener: opener)
                                .padding(.horizontal)
                        }
                        
                        Button(action: generateMore) {
                            Label("Generate More", systemImage: "arrow.clockwise")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Your Conversation Starters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .onAppear {
            generateOpeners()
        }
    }
    
    private func generateOpeners() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                let openerResult = try await appState.openerEngine.generateOpeners(
                    from: result,
                    profile: nil,
                    style: nil,
                    count: 5
                )
                
                await MainActor.run {
                    self.openers = openerResult.openers
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateMore() {
        onGenerateMore()
        generateOpeners()
    }
}

struct OpenerCard: View {
    let opener: Opener
    @State private var feedback: Feedback? = nil
    @EnvironmentObject var appState: AppState
    
    enum Feedback {
        case liked
        case disliked
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(opener.style.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { provideFeedback(.liked) }) {
                        Image(systemName: feedback == .liked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(feedback == .liked ? .green : .gray)
                            .font(.system(size: 20))
                    }
                    
                    Button(action: { provideFeedback(.disliked) }) {
                        Image(systemName: feedback == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .foregroundColor(feedback == .disliked ? .red : .gray)
                            .font(.system(size: 20))
                    }
                }
            }
            
            Text(opener.text)
                .font(.system(size: 18, weight: .medium))
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)
            
            if let explanation = opener.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func provideFeedback(_ type: Feedback) {
        feedback = type
        appState.recordFeedback(openerId: opener.id, isPositive: type == .liked)
    }
}