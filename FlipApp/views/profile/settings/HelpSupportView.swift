import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HelpSupportView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background gradient
            Theme.darkPurpleGradient.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Header
                HStack {
                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal).padding(.top, 20)

                // Content
                VStack(spacing: 25) {
                    Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 60))
                        .foregroundColor(Theme.lightTealBlue).padding()
                        .background(
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 120, height: 120)
                        )

                    Text("Need Help?").font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(
                        "Any questions? Found a bug? Just want to say hi? Send an email to jex@jajajeev.com or hit me up on instagram at @jexpearce"
                    )
                    .font(.system(size: 18)).foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center).padding(.horizontal, 25)

                    // Contact buttons
                    VStack(spacing: 15) {
                        ContactButton(icon: "envelope.fill", text: "jex@jajajeev.com") {
                            if let url = URL(string: "mailto:jex@jajajeev.com") {
                                UIApplication.shared.open(url)
                            }
                        }

                        ContactButton(icon: "camera.fill", text: "@jexpearce") {
                            if let url = URL(string: "instagram://user?username=jexpearce") {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                                else if let webURL = URL(string: "https://instagram.com/jexpearce")
                                {
                                    UIApplication.shared.open(webURL)
                                }
                            }
                        }
                    }
                    .padding(.top, 15)
                }

                Spacer()
            }
            .padding()
        }
    }
}
