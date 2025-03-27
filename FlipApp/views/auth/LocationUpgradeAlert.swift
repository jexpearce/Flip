import Foundation
//
//  LocationUpgradeAlert.swift
//  FlipApp
//
//  Created by Jex Pearce on 3/17/25.
//
import SwiftUI

// One-time alert to upgrade location permission
struct LocationUpgradeAlert: View {
    @Binding var isPresented: Bool
    @State private var isPrimaryCTA = false
    @State private var isSecondaryCTA = false
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Location icon with pulse animation
                ZStack {
                    Circle()
                        .fill(Theme.yellow.opacity(0.3))
                        .frame(width: 80, height: 80)

                    Image(systemName: "location.fill")
                        .font(.system(size: 35))
                        .foregroundColor(Theme.yellow)
                        .shadow(color: Theme.yellow.opacity(0.5), radius: 6)
                }

                // Title
                Text("IMPROVE YOUR EXPERIENCE")
                    .font(.system(size: 22, weight: .black))
                    .tracking(1)
                    .foregroundColor(.white)
                    .shadow(color: Theme.yellowShadow, radius: 4)
                    .multilineTextAlignment(.center)

                // Description
                Text(
                    "For best experience, change location to \"Always Allow\" in Settings. This unlocks regional leaderboards, and the Friends Map, and also allows you to flip with the screen off."
                )
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

                // Feature comparison
                VStack(spacing: 10) {
                    featureRow(
                        text: "Track sessions with screen off",
                        limited: false,
                        always: true
                    )
                }
                .padding(.vertical, 10)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring()) { isPrimaryCTA = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            permissionManager.openLocationSettings()
                            permissionManager.hasShownLocationUpgradeAlert =
                                true
                            isPresented = false
                        }
                    }) {
                        Text("OPEN SETTINGS")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 250, height: 50)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Theme.yellowAccentGradient)

                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0.2),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: Theme.yellowShadow, radius: 8)
                            .scaleEffect(isPrimaryCTA ? 0.95 : 1.0)
                    }

                    Button(action: {
                        withAnimation(.spring()) { isSecondaryCTA = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            permissionManager.hasShownLocationUpgradeAlert =
                                true
                            isPresented = false
                        }
                    }) {
                        Text("CONTINUE WITHOUT")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 10)
                            .scaleEffect(isSecondaryCTA ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Theme.darkGray)

                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.3))

                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .frame(maxWidth: 350)
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func featureRow(text: String, limited: Bool, always: Bool)
        -> some View
    {
        HStack {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            // Limited permission icon
            Image(systemName: limited ? "checkmark" : "xmark")
                .foregroundColor(limited ? .green : .red)
                .frame(width: 30)

            // Always permission icon
            Image(systemName: always ? "checkmark" : "xmark")
                .foregroundColor(always ? .green : .red)
                .frame(width: 30)
        }
        .padding(.horizontal, 20)
    }
}
