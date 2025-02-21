//
//  BeginButton.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/21/25.
//

import Foundation

import SwiftUI

struct BeginButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            withAnimation(.spring()) {
                isPulsing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPressed = false
                isPulsing = false
            }
            action()
        }) {
            Text("BEGIN")
                .font(.system(size: 24, weight: .black))  // Changed to match app font
                .tracking(4)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    ZStack {
                        // Base gradient
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 129/255, green: 140/255, blue: 248/255),
                                        Color(red: 99/255, green: 102/255, blue: 241/255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Glass effect
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.1))
                        
                        // Glowing border
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: isPulsing ? 3 : 0)
                    }
                )
                .shadow(
                    color: Color(red: 129/255, green: 140/255, blue: 248/255).opacity(0.5),
                    radius: isPulsing ? 15 : 8
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .padding(.horizontal, 40)
        .padding(.top, 10)
    }
}