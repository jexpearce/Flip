import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class MapConsentManager: ObservableObject {
    static let shared = MapConsentManager()

    @Published var hasAcceptedMapPrivacy = false
    @Published var showMapPrivacyAlert = false

    private let userDefaults = UserDefaults.standard
    private let mapConsentKey = "hasAcceptedMapPrivacy"
    private let db = Firestore.firestore()
    private var pendingCompletion: ((Bool) -> Void)?

    init() {
        // Check if user has already accepted in UserDefaults
        hasAcceptedMapPrivacy = userDefaults.bool(forKey: mapConsentKey)

        // For existing users, also check Firestore (in case UserDefaults was reset)
        if !hasAcceptedMapPrivacy, let userId = Auth.auth().currentUser?.uid {
            db.collection("users").document(userId).collection("settings").document("mapPrivacy")
                .getDocument { [weak self] document, error in
                    if let data = document?.data(),
                        let hasAccepted = data["hasAcceptedMapPrivacy"] as? Bool, hasAccepted
                    {
                        DispatchQueue.main.async {
                            print("Found existing map consent in Firestore")
                            self?.hasAcceptedMapPrivacy = true
                            self?.userDefaults.set(true, forKey: self?.mapConsentKey ?? "")
                        }
                    }
                }
        }
    }

    func checkAndRequestConsent(completion: @escaping (Bool) -> Void) {
        print("Checking map consent: hasAcceptedMapPrivacy = \(hasAcceptedMapPrivacy)")

        // If already accepted, just return true
        if hasAcceptedMapPrivacy {
            print("Map consent already granted, proceeding")
            completion(true)
            return
        }

        // Otherwise show alert and store completion handler for later
        print("Showing map privacy alert")
        pendingCompletion = completion

        // Important: ensure this happens on main thread
        DispatchQueue.main.async { self.showMapPrivacyAlert = true }
    }

    func acceptMapPrivacy() {
        print("User accepted map privacy")
        hasAcceptedMapPrivacy = true
        userDefaults.set(true, forKey: mapConsentKey)

        DispatchQueue.main.async { self.showMapPrivacyAlert = false }

        // Save to Firestore for syncing across devices
        if let userId = Auth.auth().currentUser?.uid {
            db.collection("users").document(userId).collection("settings").document("mapPrivacy")
                .setData(["hasAcceptedMapPrivacy": true], merge: true)
        }

        if let completion = pendingCompletion {
            completion(true)
            pendingCompletion = nil
        }
    }

    func rejectMapPrivacy() {
        print("User rejected map privacy")
        hasAcceptedMapPrivacy = false
        userDefaults.set(false, forKey: mapConsentKey)

        DispatchQueue.main.async { self.showMapPrivacyAlert = false }

        if let completion = pendingCompletion {
            completion(false)
            pendingCompletion = nil
        }
    }
}
struct MapPrivacyAlert: View {
    @Binding var isPresented: Bool
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var animateContent = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Only show content when isPresented is true
            if isVisible {
                // Dimmed background
                Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

                // Alert content
                VStack(spacing: 25) {
                    // Header with icon
                    VStack(spacing: 12) {
                        // Map icon with pulse animation
                        ZStack {
                            // Outer pulse
                            Circle().fill(Theme.darkRed.opacity(0.3)).frame(width: 90, height: 90)
                                .scaleEffect(animateContent ? 1.3 : 0.8)
                                .opacity(animateContent ? 0.0 : 0.5)

                            // Inner circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.darkRed, Theme.darkerRed],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 70, height: 70)

                            // Icon
                            Image(systemName: "map.fill").font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: Color.white.opacity(0.5), radius: 4)
                        }

                        Text("FRIENDS MAP PRIVACY").font(.system(size: 20, weight: .black))
                            .tracking(4).foregroundColor(.white)
                            .shadow(color: Theme.darkRed.opacity(0.6), radius: 8)
                    }
                    .padding(.top, 10)

                    // Explanation text
                    Text(
                        "The Friends Map feature shows your focus session locations to other users. Your privacy is important to us:"
                    )
                    .font(.system(size: 16)).foregroundColor(.white).multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                    // Privacy bullet points
                    VStack(alignment: .leading, spacing: 15) {
                        privacyPoint(
                            icon: "checkmark.circle.fill",
                            text: "Only your last 3 session locations are shown"
                        )
                        privacyPoint(
                            icon: "checkmark.circle.fill",
                            text: "Your current location is NEVER stored or shared"
                        )
                        privacyPoint(
                            icon: "checkmark.circle.fill",
                            text: "You can change map privacy settings anytime"
                        )
                    }
                    .padding(.horizontal, 20)

                    // Buttons
                    HStack(spacing: 15) {
                        // Decline button
                        Button(action: { handleReject() }) {
                            Text("Decline").font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white).frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }

                        // Accept button
                        Button(action: { handleAccept() }) {
                            Text("Accept").font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white).frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12).fill(Theme.darkRed)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 10)
                }
                .padding(25)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.mediumMidnightPurple, Theme.lighterPurple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Glass effect
                        RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.05))

                        // Border
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .frame(maxWidth: 350).shadow(color: Color.black.opacity(0.3), radius: 20)
                .scaleEffect(animateContent ? 1 : 0.8)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .onChange(of: isPresented) {
            print("MapPrivacyAlert isPresented changed to: \(isPresented)")
            if isPresented {
                showAlert()
            }
            else {
                hideAlert()
            }
        }
        .onAppear {
            // Check if we should be visible on appear
            print("MapPrivacyAlert appeared, isPresented = \(isPresented)")
            if isPresented { showAlert() }
        }
    }

    private func showAlert() {
        print("Showing privacy alert")
        isVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { animateContent = true }

            // Start the pulse animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
        }
    }

    private func hideAlert() {
        print("Hiding privacy alert")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { animateContent = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isVisible = false }
    }

    private func handleAccept() {
        print("User tapped Accept")
        withAnimation { isPresented = false }
        onAccept()
    }

    private func handleReject() {
        print("User tapped Decline")
        withAnimation { isPresented = false }
        onReject()
    }

    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.darkRed).font(.system(size: 16))
                .frame(width: 24, alignment: .center)

            Text(text).font(.system(size: 15)).foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
    }
}
