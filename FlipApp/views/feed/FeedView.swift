import SwiftUI
import FirebaseAuth

struct FeedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("FEED").title()
                
                ForEach(viewModel.feedSessions) { session in
                    FeedSessionCard(session: session)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            viewModel.loadFeed()
        }
    }
}


class FeedViewModel: ObservableObject {
    @Published var feedSessions: [Session] = []
    private let firebaseManager = FirebaseManager.shared
    
    func loadFeed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get friend list
        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                else { return }
                
                // Load sessions from friends
                self?.loadFriendSessions(friendIds: userData.friends)
            }
    }
    
    private func loadFriendSessions(friendIds: [String]) {
        firebaseManager.db.collection("sessions")
            .whereField("userId", in: friendIds)
            .order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.feedSessions = documents.compactMap { document in
                    try? document.data(as: Session.self)
                }
            }
    }
}