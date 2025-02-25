import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var signUpSuccess = false
    
    init() {
        // Check for existing auth state when initializing
        setupAuthStateListener()
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    private func setupAuthStateListener() {
        // This listener will persist across app launches
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                
                // If we have a user, ensure FirebaseManager has current user data
                if let user = user {
                    FirebaseManager.shared.db.collection("users").document(user.uid)
                        .getDocument { document, error in
                            if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                                FirebaseManager.shared.currentUser = userData
                            }
                        }
                }
            }
        }
    }

    func signUp(
        email: String, password: String, username: String,
        completion: @escaping () -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) {
            [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    completion()
                    return
                }

                if let user = result?.user {
                    let userData: [String: Any] = [
                        "id": user.uid,
                        "username": username,
                        "totalFocusTime": 0,
                        "totalSessions": 0,
                        "longestSession": 0,
                        "friends": [],
                        "friendRequests": [],
                        "sentRequests": []
                    ]

                    FirebaseManager.shared.db.collection("users").document(
                        user.uid
                    )
                    .setData(userData) { [weak self] error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self?.showAlert = true
                                self?.alertMessage = error.localizedDescription
                            } else {
                                self?.signUpSuccess = true
                                // isAuthenticated will be handled by the listener
                            }
                            completion()
                        }
                    }
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void = { _ in }) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    completion(false)
                    return
                }
                // Clear any existing session state
                UserDefaults.standard.removeObject(forKey: "currentState")
                UserDefaults.standard.removeObject(forKey: "remainingSeconds")
                UserDefaults.standard.removeObject(forKey: "remainingPauses")
                UserDefaults.standard.removeObject(forKey: "isFaceDown")
                
                // isAuthenticated will be handled by the listener
                completion(true)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // isAuthenticated will be handled by the listener
        } catch {
            showAlert = true
            alertMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    deinit {
        // Clean up the auth state listener
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}
