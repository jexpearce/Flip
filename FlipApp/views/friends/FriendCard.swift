//
//  FriendCard.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/9/25.
import Foundation
import SwiftUI

struct FriendCard: View {
    let friend: FirebaseManager.FlipUser
    @State private var isPressed = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(friend.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(friend.totalSessions) sessions")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(friend.totalFocusTime) min")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                HStack(spacing: 6) {
                    Text("total focus time")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Theme.buttonGradient)
                    .opacity(0.1)
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}