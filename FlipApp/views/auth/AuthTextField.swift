// AuthTextField.swift
import SwiftUI
import FirebaseAuth

struct AuthTextField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 20)
                .retroGlow()

            if isSecure {
                SecureField(
                    "", text: $text,
                    prompt: Text(placeholder)
                        .foregroundColor(Theme.offWhite)
                ).foregroundStyle(.white)
            } else {
                TextField(
                    "", text: $text,
                    prompt: Text(placeholder)
                        .foregroundColor(Theme.offWhite)
                )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .foregroundStyle(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}