// FailedLockView.swift
import ActivityKit
import SwiftUI
import WidgetKit

struct FailedLockView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .retroGlow()

            Text("Session Failed")
                .font(.system(size: 24, weight: .bold))
                .tracking(4)
                .foregroundColor(.white)
                .retroGlow()

            Text("Phone was moved too many times")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Theme.darkGray)
    }
}
