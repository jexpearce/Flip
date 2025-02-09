import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(colors: [Theme.darkGray, Color.black],
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 35) {
                // Logo Section
                VStack(spacing: 20) {
                    HStack(spacing: 15) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.neonYellow)
                            .shadow(color: Theme.neonYellow.opacity(0.5), radius: 10)
                        
                        Text("FLIP")
                            .font(.system(size: 60, weight: .black, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(.white)
                    }
                    
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                // Auth Fields
                VStack(spacing: 20) {
                    if isSignUp {
                        AuthTextField(text: $username,
                                    icon: "person.fill",
                                    placeholder: "Username")
                    }
                    
                    AuthTextField(text: $email,
                                icon: "envelope.fill",
                                placeholder: "Email",
                                keyboardType: .emailAddress)
                    
                    AuthTextField(text: $password,
                                icon: "lock.fill",
                                placeholder: "Password",
                                isSecure: true)
                }
                .padding(.horizontal, 30)
                
                // Sign In/Up Button
                Button(action: {
                    isLoading = true
                    if isSignUp {
                        authManager.signUp(email: email, password: password, username: username)
                    } else {
                        authManager.signIn(email: email, password: password)
                    }
                }) {
                    ZStack {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.black)
                            .opacity(isLoading ? 0 : 1)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Theme.neonYellow)
                    .cornerRadius(30)
                    .shadow(color: Theme.neonYellow.opacity(0.3), radius: 10)
                }
                .padding(.horizontal, 30)
                
                // Toggle Sign In/Up
                Button(action: {
                    withAnimation { isSignUp.toggle() }
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(Theme.neonYellow)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.top, 50)
        }
    }
}

struct AuthTextField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(Theme.neonYellow)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FlipTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(Theme.darkGray)
            .cornerRadius(15)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
            )
    }
}
