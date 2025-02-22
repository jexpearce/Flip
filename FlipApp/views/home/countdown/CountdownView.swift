import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var numberScale: CGFloat = 1.0
    @State private var numberOpacity: Double = 1.0
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Title with animated glow
            Text("GET READY")
                .font(.system(size: 28, weight: .black))
                .tracking(8)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(isGlowing ? 0.7 : 0.3), radius: isGlowing ? 15 : 8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                        isGlowing = true
                    }
                }

            // Animated Countdown Number
            Text("\(appManager.countdownSeconds)")
                .font(.system(size: 120, weight: .black))
                .foregroundColor(.white)
                .scaleEffect(numberScale)
                .opacity(numberOpacity)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 15)
                .onChange(of: appManager.countdownSeconds) { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        numberScale = 1.4
                        numberOpacity = 0.7
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            numberScale = 1.0
                            numberOpacity = 1.0
                        }
                    }
                }

            // Instructions
            VStack(spacing: 15) {
                // Step 1
                instructionRow(
                    number: "1",
                    text: "TURN OFF PHONE"
                )

                // Step 2
                instructionRow(
                    number: "2",
                    text: "FLIP!"
                )
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Theme.mainGradient
                
                // Subtle animated circles in background
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 200, height: 200)
                        .opacity(0.05)
                        .offset(x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -100...100))
                        .blur(radius: 50)
                }
            }
        )
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 15) {
            // Number circle with glass effect
            ZStack {
                Circle()
                    .fill(Theme.buttonGradient)
                    .opacity(0.1)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                Text(number)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)

            Text(text)
                .font(.system(size: 20, weight: .heavy))
                .tracking(2)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
        }
    }
}