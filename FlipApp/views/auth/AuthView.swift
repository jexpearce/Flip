import FirebaseAuth
import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var isKeyboardVisible = false
    @State private var selectedField: Field? = nil
    
    private enum Field: Hashable {
        case email, password, username
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                Theme.mainGradient
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 35) {
                        // Logo Section
                        LogoSection(isSignUp: isSignUp)
                            .scaleEffect(isKeyboardVisible ? 0.8 : 1.0)
                            .padding(.top, isKeyboardVisible ? 20 : 60)
                        
                        // Auth Fields
                        VStack(spacing: 20) {
                            if isSignUp {
                                ImprovedAuthField(
                                    text: $username,
                                    icon: "person.fill",
                                    placeholder: "Username",
                                    isSelected: selectedField == .username,
                                    onTap: { selectedField = .username }
                                )
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                            
                            ImprovedAuthField(
                                text: $email,
                                icon: "envelope.fill",
                                placeholder: "Email",
                                keyboardType: .emailAddress,
                                isSelected: selectedField == .email,
                                onTap: { selectedField = .email }
                            )
                            
                            ImprovedAuthField(
                                text: $password,
                                icon: "lock.fill",
                                placeholder: "Password",
                                isSecure: true,
                                isSelected: selectedField == .password,
                                onTap: { selectedField = .password }
                            )
                        }
                        .padding(.horizontal, 30)
                        
                        // Sign In/Up Button
                        Button(action: handleAuth) {
                            ZStack {
                                Text(isSignUp ? "Create Account" : "Sign In")
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
                            .background(
                                Theme.neonYellow
                                    .brightness(isLoading ? -0.2 : 0)
                            )
                            .cornerRadius(30)
                            .shadow(color: Theme.neonYellow.opacity(0.3), radius: 10)
                            .scaleEffect(isLoading ? 0.95 : 1)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 30)
                        .animation(.spring(), value: isLoading)
                        
                        // Toggle Sign In/Up
                        Button(action: {
                            withAnimation(.spring()) {
                                isSignUp.toggle()
                                selectedField = nil
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundColor(Theme.neonYellow)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .padding(.horizontal)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .onTapGesture {
            selectedField = nil
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                         to: nil, from: nil, for: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring()) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring()) {
                isKeyboardVisible = false
            }
        }
    }
    
    private func handleAuth() {
        isLoading = true
        
        if isSignUp {
            authManager.signUp(email: email, password: password, username: username) {
                isLoading = false
            }
        } else {
            authManager.signIn(email: email, password: password)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
}

struct LogoSection: View {
    let isSignUp: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.neonYellow)
                    .shadow(color: Theme.neonYellow.opacity(0.5), radius: 10)
                    .rotationEffect(.degrees(isSignUp ? 180 : 0))
                
                Text("FLIP")
                    .font(.system(size: 60, weight: .black, design: .monospaced))
                    .tracking(5)
                    .foregroundColor(.white)
            }
            
            Text(isSignUp ? "Create Account" : "Welcome Back")
                .font(.title2)
                .foregroundColor(.gray)
                .transition(.opacity)
        }
    }
}

struct ImprovedAuthField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? Theme.neonYellow : Theme.neonYellow.opacity(0.7))
                .frame(width: 20)
                .scaleEffect(isSelected ? 1.1 : 1.0)
            
            Group {
                if isSecure {
                    SecureField("", text: $text,
                              prompt: Text(placeholder)
                        .foregroundColor(Theme.offWhite))
                } else {
                    TextField("", text: $text,
                            prompt: Text(placeholder)
                        .foregroundColor(Theme.offWhite))
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                }
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Theme.darkGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Theme.neonYellow : Theme.neonYellow.opacity(0.3),
                               lineWidth: isSelected ? 2 : 1)
                )
        )
        .onTapGesture {
            onTap()
        }
        .animation(.spring(), value: isSelected)
    }
}