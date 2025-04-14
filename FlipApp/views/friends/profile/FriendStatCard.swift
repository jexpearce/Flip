import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct FriendStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let delay: Double

    @State private var animate = false

    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 60, height: 60)

                Image(systemName: icon).font(.system(size: 30)).foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 5)
            }
            .scaleEffect(animate ? 1 : 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .bold)).tracking(1)
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value).font(.system(size: 30, weight: .black)).foregroundColor(.white)
                        .shadow(color: color.opacity(0.5), radius: 6)

                    Text(unit).font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                }
                .opacity(animate ? 1 : 0).offset(x: animate ? 0 : -20)
            }

            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { animate = true }
            }
        }
    }
}
