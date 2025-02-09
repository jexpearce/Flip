import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var signUpSuccess = false
    
    func signUp(email: String, password: String, username: String, completion: @escaping () -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
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
                        "friends": []
                    ]
                    
                    FirebaseManager.shared.db.collection("users").document(user.uid)
                        .setData(userData) { [weak self] error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self?.showAlert = true
                                    self?.alertMessage = error.localizedDescription
                                } else {
                                    self?.signUpSuccess = true
                                    self?.isAuthenticated = true
                                }
                                completion()
                            }
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