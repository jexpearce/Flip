import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    
    func signUp(email: String, password: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                // Create user profile in Firestore
                let userData: [String: Any] = [
                    "id": user.uid,
                    "username": username,
                    "totalFocusTime": 0,
                    "totalSessions": 0,
                    "longestSession": 0,
                    "friends": []
                ]
                
                FirebaseManager.shared.db.collection("users").document(user.uid)
                    .setData(userData) { error in
                        if error == nil {
                            self?.isAuthenticated = true
                        }
                    }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if result != nil {
                self?.isAuthenticated = true
            }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        isAuthenticated = false
    }
}