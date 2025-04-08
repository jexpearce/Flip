import FirebaseAuth
import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var locationPermissionManager = LocationPermissionManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var isKeyboardVisible = false
    @State private var selectedField: Field? = nil
    @State private var isButtonPressed = false
    @State private var showPassword = false
    @State private var showSuccessOverlay = false

    // Animation states
    @State private var isFlipAnimating = false
    @State private var logoScale: CGFloat = 1.0

    private enum Field: Hashable { case email, password, username }

    var body: some View {
        ZStack {
            // Main content
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 35) {
                        // Logo section with FL!P logo
                        VStack(spacing: 0) {
                            // Stylized FLIP logo with flipped "i"
                            HStack(spacing: 2) {
                                Text("F").font(.system(size: 80, weight: .black)).tracking(2)
                                    .foregroundColor(.white)

                                Text("L").font(.system(size: 80, weight: .black)).tracking(2)
                                    .foregroundColor(.white)

                                // Upside-down "i"
                                Text("i").font(.system(size: 80, weight: .black)).tracking(2)
                                    .foregroundColor(.white).rotationEffect(.degrees(180))

                                Text("P").font(.system(size: 80, weight: .black)).tracking(2)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Theme.indigoGlow, radius: 10).scaleEffect(logoScale)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6),
                                value: logoScale
                            )

                            // Animated arrow icon
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                                .shadow(color: Theme.indigoGlow, radius: 6)
                                .rotationEffect(.degrees(isFlipAnimating ? 360 : 0))
                                .animation(
                                    .spring(response: 2.0, dampingFraction: 0.6)
                                        .repeatForever(autoreverses: false),
                                    value: isFlipAnimating
                                )
                            VStack(spacing: 4) {

                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                                    .shadow(color: Theme.indigoGlow, radius: 6)
                            }
                            .padding(.top, 8).scaleEffect(isKeyboardVisible ? 0.9 : 1.0)
                        }
                        .scaleEffect(isKeyboardVisible ? 0.8 : 1.0)
                        .padding(.top, isKeyboardVisible ? 20 : 60)

                        // Auth fields with enhanced styling
                        VStack(spacing: 20) {
                            if isSignUp {
                                EnhancedAuthField(
                                    text: $username,
                                    icon: "person.fill",
                                    placeholder: "Username",
                                    isSelected: selectedField == .username,
                                    accentColor: Theme.indigoAccent,
                                    onTap: { selectedField = .username }
                                )
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }

                            EnhancedAuthField(
                                text: $email,
                                icon: "envelope.fill",
                                placeholder: "Email",
                                keyboardType: .emailAddress,
                                isSelected: selectedField == .email,
                                accentColor: Theme.indigoAccent,
                                onTap: { selectedField = .email }
                            )

                            // Password field with show/hide toggle
                            HStack(spacing: 15) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(
                                        selectedField == .password ? .white : .white.opacity(0.7)
                                    )
                                    .frame(width: 20)
                                    .scaleEffect(selectedField == .password ? 1.1 : 1.0)
                                    .shadow(color: Theme.indigoGlow, radius: 4)

                                Group {
                                    if showPassword {
                                        TextField(
                                            "",
                                            text: $password,
                                            prompt: Text("Password")
                                                .foregroundColor(.white.opacity(0.4))
                                        )
                                        .textInputAutocapitalization(.never)
                                    }
                                    else {
                                        SecureField(
                                            "",
                                            text: $password,
                                            prompt: Text("Password")
                                                .foregroundColor(.white.opacity(0.4))
                                        )
                                    }
                                }
                                .foregroundColor(.white)

                                Button(action: { withAnimation { showPassword.toggle() } }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.6)).frame(width: 20)
                                }
                            }
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.05))

                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(
                                                        selectedField == .password ? 0.5 : 0.2
                                                    ),
                                                    Color.white.opacity(
                                                        selectedField == .password ? 0.2 : 0.1
                                                    ),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: selectedField == .password ? 2 : 1
                                        )
                                }
                            )
                            .shadow(
                                color: selectedField == .password ? Theme.indigoGlow : .clear,
                                radius: 4
                            )
                            .onTapGesture { selectedField = .password }
                            .animation(.spring(), value: selectedField)
                        }
                        .padding(.horizontal, 30)

                        // Enhanced Sign In/Up Button with animations
                        Button(action: {
                            withAnimation(.spring()) {
                                isButtonPressed = true
                                logoScale = 1.1
                                handleAuth()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isButtonPressed = false
                                logoScale = 1.0
                            }
                        }) {
                            ZStack {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 24, weight: .black)).tracking(4)
                                    .foregroundColor(.white).opacity(isLoading ? 0 : 1)

                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 60)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Theme.indigoAccent.opacity(0.8),
                                                    Theme.indigoAccent.opacity(0.5),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Theme.silveryGradient, lineWidth: 1)
                                }
                            )
                            .shadow(color: Theme.indigoGlow, radius: isButtonPressed ? 15 : 8)
                            .scaleEffect(isButtonPressed || isLoading ? 0.95 : 1.0)
                        }
                        .disabled(isLoading).padding(.horizontal, 30)

                        // Toggle Sign In/Up with indigo glow effect
                        Button(action: {
                            withAnimation(.spring()) {
                                isSignUp.toggle()
                                selectedField = nil
                            }
                        }) {
                            Text(
                                isSignUp
                                    ? "Already have an account? Sign In"
                                    : "Don't have an account? Sign Up"
                            )
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: Theme.indigoGlow, radius: 4)
                        }
                        .padding(.bottom, 20)

                        // Google Sign-In Button
                        Button(action: {
                            authManager.signInWithGoogle { success in
                                if !success { isLoading = false }
                            }
                        }) {
                            Image("google-logo")  // Ensure this matches the name in Assets.xcassets
                                .resizable().aspectRatio(contentMode: .fit).frame(height: 50)  // Adjust as needed
                        }
                        .padding(.horizontal, 30)

                        // Apple Sign-In Button
                        Button(action: { authManager.authenticateWithApple() }) {
                            HStack {
                                Image(systemName: "applelogo").resizable()
                                    .aspectRatio(contentMode: .fit).frame(height: 20)
                                Text("Sign in with Apple")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(Color.black)
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                }
                            )
                        }
                        .padding(.horizontal, 30).padding(.top, 10)
                    }
                    .padding(.horizontal).frame(minHeight: geometry.size.height)
                }
            }
            .onTapGesture {
                selectedField = nil
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            ) { _ in withAnimation(.spring()) { isKeyboardVisible = true } }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in withAnimation(.spring()) { isKeyboardVisible = false } }

            // Error Alert
            .alert(isPresented: $authManager.showAlert) {
                Alert(
                    title: Text("Authentication Error"),
                    message: Text(authManager.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }

            // Enhanced Success Overlay with animations
            if showSuccessOverlay {
                Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            // Success Icon
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.mutedGreen, Theme.darkerGreen],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.green.opacity(0.5), radius: 10)
                                .padding(.top, 30)

                            // Success Title
                            VStack(spacing: 4) {
                                Text("SUCCESS").font(.system(size: 28, weight: .black)).tracking(8)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.green.opacity(0.5), radius: 8)

                                Text("成功").font(.system(size: 14)).tracking(4)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            // Message
                            Text("Your account has been created successfully!")
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.center).foregroundColor(.white)
                                .padding(.horizontal, 30).padding(.vertical, 10)

                            // Continue Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    showSuccessOverlay = false
                                    authManager.signUpSuccess = false

                                    // Add a slight delay before sign in to ensure state is updated
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        authManager.signIn(email: email, password: password) {
                                            success in
                                            // Only proceed if sign in was successful
                                            if !success {
                                                // Handle sign in failure
                                                print("Auto sign-in failed after account creation")
                                            }
                                        }
                                    }
                                }
                            }) {
                                Text("CONTINUE").font(.system(size: 20, weight: .black)).tracking(2)
                                    .foregroundColor(.white).frame(width: 200, height: 50)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Theme.indigoAccent.opacity(0.8),
                                                            Theme.indigoAccent.opacity(0.5),
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )

                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Color.white.opacity(0.1))

                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Theme.silveryGradient, lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: Theme.indigoGlow, radius: 8)
                            }
                            .padding(.bottom, 30)
                        }
                        .frame(width: 320)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20).fill(Theme.darkGray)

                                RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.3))

                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.silveryGradient2, lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 20)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    )
                    .transition(.opacity)
            }

            // Custom Location Permission Alert
            if locationPermissionManager.showCustomAlert {
                LocationPermissionAlert(
                    isPresented: $locationPermissionManager.showCustomAlert,
                    onContinue: {
                        // Request the system location permission after user acknowledges
                        locationPermissionManager.requestSystemPermission()
                    }
                )
            }

            // Background gradient
            Theme.indigoPurpleGradient.edgesIgnoringSafeArea(.all).zIndex(-1)

            // Decorative elements - top glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.indigoAccent.opacity(0.2), Theme.indigoAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300).offset(x: 150, y: -150).blur(radius: 50).zIndex(-1)

            // Bottom decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.indigoAccent.opacity(0.15), Theme.indigoAccent.opacity(0.03),
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 250, height: 250).offset(x: -120, y: 350).blur(radius: 40).zIndex(-1)
        }
        .onAppear {
            // Start animation for the flip icon
            isFlipAnimating = true
        }
        .onReceive(authManager.$signUpSuccess) { success in
            if success {
                withAnimation(.spring()) {
                    showSuccessOverlay = true
                    isLoading = false
                }

                // Start the permission flow after successful sign-up (with delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Make sure isPotentialFirstTimeUser is true to trigger InitialView
                    UserDefaults.standard.set(true, forKey: "isPotentialFirstTimeUser")
                    // Post notification to app to check and show permission flow
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowPermissionsFlow"),
                        object: nil
                    )
                }
            }
        }
    }

    private func handleAuth() {
        isLoading = true

        if isSignUp {
            authManager.signUp(email: email, password: password, username: username) {
                // Loading state is maintained if sign-up is successful
                // The success overlay will appear and handle dismissal
                if !authManager.signUpSuccess { isLoading = false }
            }
        }
        else {
            authManager.signIn(email: email, password: password) { success in
                // Only reset loading if sign in failed
                // If success is true, the app will transition to main screen
                if !success { isLoading = false }
            }
        }
    }
}

// Enhanced Auth Field with glow effects and animations
struct EnhancedAuthField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    let isSelected: Bool
    var accentColor: Color
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .frame(width: 20).scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: accentColor.opacity(0.5), radius: isSelected ? 4 : 0)

            Group {
                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundColor(.white.opacity(0.4))
                    )
                }
                else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundColor(.white.opacity(0.4))
                    )
                    .keyboardType(keyboardType).textInputAutocapitalization(.never)
                }
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.5 : 0.2),
                                Color.white.opacity(isSelected ? 0.2 : 0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        )
        .shadow(color: isSelected ? accentColor.opacity(0.2) : .clear, radius: 4)
        .onTapGesture { onTap() }.animation(.spring(), value: isSelected)
    }
}
