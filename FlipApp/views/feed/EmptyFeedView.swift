//
//  EmptyFeedView.swift
//  Flip
//
//  Created by James Pearce on 4/14/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Enhanced glowing circle with layered effect
            ZStack {
                // Base glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.mutedGreen.opacity(0.5), Theme.oliveGreen.opacity(0.0),
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 150, height: 150).blur(radius: 15)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.mutedGreen.opacity(0.7), Theme.mutedGreen.opacity(0.1),
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)

                // Icon with glow
                Image(systemName: "doc.text.image").font(.system(size: 50)).foregroundColor(.white)
                    .shadow(color: Theme.mutedGreen.opacity(0.8), radius: 10)
            }
            .padding(.top, 20)

            // Enhanced headline with layered text
            VStack(spacing: 6) {
                Text("NO SESSIONS YET").font(.system(size: 28, weight: .black)).tracking(6)
                    .foregroundColor(.white).shadow(color: Theme.mutedGreen.opacity(0.6), radius: 8)

                Text("No sessions available").font(.system(size: 14)).tracking(2)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Supportive text with better styling
            Text("Add friends to see their focus sessions in your feed")
                .font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center).padding(.horizontal, 30).padding(.top, 5)

            // Button removed as requested
        }
        .padding().padding(.horizontal, 20).padding(.bottom, 40)
    }
}
