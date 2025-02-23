import FirebaseAuth
import SwiftUI


struct FeedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("FEED")
                    .font(.system(size: 28, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                    .padding(.top, 20)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                        .padding(.top, 50)
                } else if viewModel.feedSessions.isEmpty {
                    VStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(Theme.buttonGradient)
                                .frame(width: 80, height: 80)
                                .opacity(0.2)
                            
                            Image(systemName: "person.2")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        }

                        Text("No Sessions Yet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)

                        Text("Add friends to see their focus sessions")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(viewModel.feedSessions) { session in
                        FeedSessionCard(session: session)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadFeed()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

class FeedViewModel: ObservableObject {
    @Published var feedSessions: [Session] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    private let firebaseManager = FirebaseManager.shared

    func loadFeed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                        self?.isLoading = false
                    }
                    return
                }

                guard
                    let userData = try? document?.data(
                        as: FirebaseManager.FlipUser.self)
                else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                    return
                }

                if userData.friends.isEmpty {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                    return
                }

                self?.loadFriendSessions(friendIds: userData.friends)
            }
    }

    private func loadFriendSessions(friendIds: [String]) {
        firebaseManager.db.collection("sessions")
            .whereField("userId", in: friendIds)
            .order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                    } else if let documents = snapshot?.documents {
                        self?.feedSessions = documents.compactMap { document in
                            try? document.data(as: Session.self)
                        }
                    }
                    self?.isLoading = false
                }
            }
    }
}
