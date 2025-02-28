//
//  JoinedSessionIndicator.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/28/25.
//

import Foundation
import SwiftUI

struct JoinedSessionIndicator: View {
    @ObservedObject var liveSessionManager = LiveSessionManager.shared
    @State private var isGlowing = false
    
    var body: some View {
        if let joinedSession = liveSessionManager.currentJoinedSession {
            HStack(spacing: 8) {
                // Live indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
                
                // Session info
                Text("In session with \(joinedSession.starterUsername)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Elapsed time
                Text(joinedSession.elapsedTimeString)
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.8),
                                        Color.green.opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal)
            .onAppear {
                isGlowing = true
            }
        } else {
            EmptyView()
        }
    }
}