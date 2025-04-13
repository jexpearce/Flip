import AuthenticationServices
import CryptoKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var currentUser: User?
    @Published var signUpSuccess = false  // Add this property
    private var appleSignInCompletion: ((Bool) -> Void)?

    override init() {
        super.init()
        updateAuthState()

        // Listen for auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in self?.updateAuthState() }
    }

    private func updateAuthState() {
        DispatchQueue.main.async {
            self.currentUser = Auth.auth().currentUser
            self.isAuthenticated = self.currentUser != nil
        }
    }

    func signUp(email: String, password: String, username: String, completion: @escaping () -> Void)
    {
        guard !username.isEmpty else {
            DispatchQueue.main.async {
                self.alertMessage = "Please enter a username"
                self.showAlert = true
                completion()
            }
            return
        }

        // Check username length
        if username.count < 3 || username.count > 20 {
            DispatchQueue.main.async {
                self.alertMessage = "Username must be between 3 and 20 characters"
                self.showAlert = true
                completion()
            }
            return
        }

        // Check for valid email
        if !isValidEmail(email) {
            DispatchQueue.main.async {
                self.alertMessage = "Please enter a valid email address"
                self.showAlert = true
                completion()
            }
            return
        }

        // Check password strength
        if password.count < 6 {
            DispatchQueue.main.async {
                self.alertMessage = "Password must be at least 6 characters"
                self.showAlert = true
                completion()
            }
            return
        }

        // First check if username is already taken
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error checking username: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.alertMessage = "An error occurred. Please try again."
                        self.showAlert = true
                        completion()
                    }
                    return
                }

                if let documents = snapshot?.documents, !documents.isEmpty {
                    // Username is taken
                    DispatchQueue.main.async {
                        self.alertMessage = "Username is already taken"
                        self.showAlert = true
                        completion()
                    }
                    return
                }

                // Create user account
                Auth.auth()
                    .createUser(withEmail: email, password: password) { [weak self] result, error in
                        guard let self = self else { return }

                        if let error = error {
                            DispatchQueue.main.async {
                                self.alertMessage = self.handleAuthError(error)
                                self.showAlert = true
                                completion()
                            }
                            return
                        }

                        guard let user = result?.user else {
                            DispatchQueue.main.async {
                                self.alertMessage = "Unknown error occurred"
                                self.showAlert = true
                                completion()
                            }
                            return
                        }

                        // Set display name
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = username
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error updating display name: \(error.localizedDescription)")
                            }
                        }

                        // Create user document in Firestore
                        let userData: [String: Any] = [
                            "id": user.uid, "username": username, "email": email,
                            "totalFocusTime": 0, "totalSessions": 0, "longestSession": 0,
                            "friends": [], "friendRequests": [], "sentRequests": [],
                            "createdAt": FieldValue.serverTimestamp(),
                        ]

                        db.collection("users").document(user.uid)
                            .setData(userData) { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        print(
                                            "Error saving user data: \(error.localizedDescription)"
                                        )
                                        self.alertMessage =
                                            "Account created but failed to save user data"
                                        self.showAlert = true
                                    }
                                    else {
                                        // Set the success flag for custom notification
                                        self.signUpSuccess = true
                                        // After success (where you set self.signUpSuccess = true)
                                        FirebaseManager.shared.ensureFirstTimeExperience()
                                        print("User created successfully with ID: \(user.uid)")

                                        // Store the current user in FirebaseManager
                                        let flipUser = FirebaseManager.FlipUser(
                                            id: user.uid,
                                            username: username,
                                            totalFocusTime: 0,
                                            totalSessions: 0,
                                            longestSession: 0,
                                            friends: [],
                                            friendRequests: [],
                                            sentRequests: [],
                                            profileImageURL: nil
                                        )
                                        FirebaseManager.shared.currentUser = flipUser
                                    }
                                    completion()
                                }
                            }
                    }
            }
    }

    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth()
            .signIn(withEmail: email, password: password) { [weak self] result, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.alertMessage = self.handleAuthError(error)
                        self.showAlert = true
                        completion(false)
                    }
                    return
                }

                guard let user = result?.user else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Unknown error occurred"
                        self.showAlert = true
                        completion(false)
                    }
                    return
                }
                UserSettingsManager.shared.onUserSignIn()

                // Load user data from Firestore
                self.loadUserData(userId: user.uid) {
                    // Check if this is a first-time user AFTER loading data
                    if UserDefaults.standard.bool(forKey: "isPotentialFirstTimeUser") {
                        // DON'T trigger permissions directly - let the InitialView do it
                        // DON'T reset the flag here
                        print(
                            "First-time user detected after login - InitialView will handle permissions"
                        )
                    }
                    completion(true)
                }
            }
    }

    func signOut() {
        UserSettingsManager.shared.onUserSignOut()
        // Add this line to reset the sign up success state
        self.signUpSuccess = false

        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async { self.updateAuthState() }
        }
        catch { print("Error signing out: \(error.localizedDescription)") }
    }

    private func loadUserData(userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .getDocument { document, error in
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    completion()
                    return
                }

                guard let userData = document?.data() else {
                    print("No user data found")
                    completion()
                    return
                }

                // Parse user data
                if let username = userData["username"] as? String,
                    let totalFocusTime = userData["totalFocusTime"] as? Int,
                    let totalSessions = userData["totalSessions"] as? Int,
                    let longestSession = userData["longestSession"] as? Int,
                    let friends = userData["friends"] as? [String],
                    let friendRequests = userData["friendRequests"] as? [String],
                    let sentRequests = userData["sentRequests"] as? [String]
                {

                    let profileImageURL = userData["profileImageURL"] as? String

                    let flipUser = FirebaseManager.FlipUser(
                        id: userId,
                        username: username,
                        totalFocusTime: totalFocusTime,
                        totalSessions: totalSessions,
                        longestSession: longestSession,
                        friends: friends,
                        friendRequests: friendRequests,
                        sentRequests: sentRequests,
                        profileImageURL: profileImageURL
                    )

                    // Store user in Firebase Manager
                    DispatchQueue.main.async {
                        FirebaseManager.shared.currentUser = flipUser
                        completion()
                    }
                }
                else {
                    print("Failed to parse user data")
                    completion()
                }
            }
    }

    // Helper method to validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    // Helper to convert Firebase Auth errors to user-friendly messages
    private func handleAuthError(_ error: Error) -> String {
        guard let errorCode = error as NSError? else { return "An unknown error occurred" }

        switch errorCode.code {
        case AuthErrorCode.invalidEmail.rawValue: return "Invalid email address"
        case AuthErrorCode.wrongPassword.rawValue: return "Incorrect password"
        case AuthErrorCode.userNotFound.rawValue: return "Account not found"
        case AuthErrorCode.userDisabled.rawValue: return "This account has been disabled"
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "This email is already registered"
        case AuthErrorCode.weakPassword.rawValue: return "Password is too weak"
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection"
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later"
        default: return "An error occurred: \(error.localizedDescription)"
        }
    }
}

extension AuthManager {
    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        guard let rootViewController = UIApplication.shared.topViewController() else {
            alertMessage = "Could not get root view controller"
            showAlert = true
            completion(false)
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) {
            [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.alertMessage = "Google Sign-In failed: \(error.localizedDescription)"
                self.showAlert = true
                completion(false)
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                self.alertMessage = "Missing authentication data"
                self.showAlert = true
                completion(false)
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth()
                .signIn(with: credential) { [weak self] authResult, error in
                    guard let self = self else { return }

                    if let error = error {
                        self.alertMessage = self.handleAuthError(error)
                        self.showAlert = true
                        completion(false)
                        return
                    }

                    guard let user = authResult?.user else {
                        self.alertMessage = "Authentication failed"
                        self.showAlert = true
                        completion(false)
                        return
                    }

                    // Handle new users
                    if authResult?.additionalUserInfo?.isNewUser == true {
                        // Set first-time user flags for new Google users
                        UserDefaults.standard.set(true, forKey: "isPotentialFirstTimeUser")
                        UserDefaults.standard.set(false, forKey: "hasCompletedPermissionFlow")
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                        
                        self.createGoogleUserDocument(user: user) {
                            self.loadUserData(userId: user.uid) {
                                // Post notification to show permission flow
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowPermissionsFlow"),
                                    object: nil
                                )
                                completion(true)
                            }
                        }
                    }
                    else {
                        // For existing users, check if they need to complete permissions
                        let hasCompletedPermissions = UserDefaults.standard.bool(forKey: "hasCompletedPermissionFlow")
                        if !hasCompletedPermissions {
                            // Set flags to trigger permission flow
                            UserDefaults.standard.set(true, forKey: "isPotentialFirstTimeUser")
                            UserDefaults.standard.set(false, forKey: "hasCompletedPermissionFlow")
                            
                            // Post notification to show permission flow
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowPermissionsFlow"),
                                object: nil
                            )
                        }
                        self.loadUserData(userId: user.uid) { completion(true) }
                    }
                }
        }
    }

    private func createGoogleUserDocument(user: User, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "id": user.uid, "username": user.displayName ?? "User\(Int.random(in: 1000...9999))",
            "email": user.email ?? "", "totalFocusTime": 0, "totalSessions": 0, "longestSession": 0,
            "friends": [], "friendRequests": [], "sentRequests": [],
            "createdAt": FieldValue.serverTimestamp(),
        ]

        db.collection("users").document(user.uid)
            .setData(userData) { error in
                if let error = error {
                    print("Error creating user document: \(error.localizedDescription)")
                }
                completion()
            }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }

        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )

        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }
    @available(iOS 13, *) private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()

        return hashString
    }

    // Method to initiate Apple Sign In flow with Firebase
    func authenticateWithApple(completion: @escaping (Bool) -> Void) {
        let nonce = randomNonceString()
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        // Store the completion handler and nonce for use after authentication
        self.appleSignInCompletion = completion
        UserDefaults.standard.set(nonce, forKey: "appleSignInNonce")
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    // ASAuthorizationControllerDelegate methods
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            print("Unable to retrieve Apple ID credential")
            if let completion = self.appleSignInCompletion {
                completion(false)
                self.appleSignInCompletion = nil
            }
            return
        }
        // Get Apple Sign In data
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        // Get the identity token data and convert to string
        guard let identityTokenData = appleIDCredential.identityToken,
            let identityToken = String(data: identityTokenData, encoding: .utf8),
            let nonce = UserDefaults.standard.string(forKey: "appleSignInNonce")
        else {
            print("Unable to fetch identity token or nonce")
            if let completion = self.appleSignInCompletion {
                completion(false)
                self.appleSignInCompletion = nil
            }
            return
        }
        // Create Firebase credential with Apple ID token and nonce
        let credential = OAuthProvider.appleCredential(
            withIDToken: identityToken,
            rawNonce: nonce,
            fullName: fullName,
        )
        // Sign in to Firebase with the Apple credential
        Auth.auth()
            .signIn(with: credential) { [weak self] (authResult, error) in
                guard let self = self else { return }
                // Clear the stored nonce
                UserDefaults.standard.removeObject(forKey: "appleSignInNonce")
                if let error = error {
                    print("Firebase sign in with Apple failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.alertMessage = "Sign in failed: \(error.localizedDescription)"
                        self.showAlert = true
                        if let completion = self.appleSignInCompletion {
                            completion(false)
                            self.appleSignInCompletion = nil
                        }
                    }
                    return
                }
                guard let user = authResult?.user else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Authentication failed"
                        self.showAlert = true
                        if let completion = self.appleSignInCompletion {
                            completion(false)
                            self.appleSignInCompletion = nil
                        }
                    }
                    return
                }
                // Check if this is a new user
                if authResult?.additionalUserInfo?.isNewUser == true {
                    // For new users, create a document in Firestore
                    var displayName = "User\(Int.random(in: 1000...9999))"
                    if let firstName = fullName?.givenName, let lastName = fullName?.familyName {
                        displayName = "\(firstName) \(lastName)"
                    }
                    else if let firstName = fullName?.givenName {
                        displayName = firstName
                    }
                    else if let lastName = fullName?.familyName {
                        displayName = lastName
                    }
                    // Set display name for the user
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Error updating display name: \(error.localizedDescription)")
                        }
                    }
                    // Create the user document
                    self.createAppleUserDocument(
                        user: user,
                        displayName: displayName,
                        email: email ?? user.email ?? ""
                    ) {
                        self.loadUserData(userId: user.uid) {
                            UserSettingsManager.shared.onUserSignIn()
                            if let completion = self.appleSignInCompletion {
                                completion(true)
                                self.appleSignInCompletion = nil
                            }
                        }
                    }
                }
                else {
                    // Existing user, just load their data
                    self.loadUserData(userId: user.uid) {
                        UserSettingsManager.shared.onUserSignIn()
                        if let completion = self.appleSignInCompletion {
                            completion(true)
                            self.appleSignInCompletion = nil
                        }
                    }
                }
            }
    }
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // Handle error
        DispatchQueue.main.async {
            self.alertMessage = "Apple Sign In failed: \(error.localizedDescription)"
            self.showAlert = true
            if let completion = self.appleSignInCompletion {
                completion(false)
                self.appleSignInCompletion = nil
            }
        }
        print("Apple ID authorization failed: \(error.localizedDescription)")
    }
    // ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else { fatalError("No window found") }
        return window
    }
    // Helper method to create a user document for Apple Sign In users
    private func createAppleUserDocument(
        user: User,
        displayName: String,
        email: String,
        completion: @escaping () -> Void
    ) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "id": user.uid, "username": displayName, "email": email, "totalFocusTime": 0,
            "totalSessions": 0, "longestSession": 0, "friends": [], "friendRequests": [],
            "sentRequests": [], "createdAt": FieldValue.serverTimestamp(),
        ]
        db.collection("users").document(user.uid)
            .setData(userData) { error in
                if let error = error {
                    print("Error creating user document: \(error.localizedDescription)")
                }
                completion()
            }
    }
}

extension UIApplication {
    func topViewController() -> UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?
                .rootViewController
        else { return nil }

        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}
