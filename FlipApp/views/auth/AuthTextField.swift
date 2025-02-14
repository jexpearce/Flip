import FirebaseAuth
import SwiftUI

struct AuthTextField: View {
  @Binding var text: String
  let icon: String
  let placeholder: String
  var isSecure: Bool = false
  var keyboardType: UIKeyboardType = .default

  var body: some View {
    HStack(spacing: 15) {
      Image(systemName: icon)
        .foregroundColor(Theme.neonYellow)
        .frame(width: 20)

      if isSecure {
        SecureField(
          "", text: $text,
          prompt: Text(placeholder)
            .foregroundColor(Theme.offWhite)
        ).foregroundStyle(Theme.neonYellow)
      } else {
        TextField(
          "", text: $text,
          prompt: Text(placeholder)
            .foregroundColor(Theme.offWhite)
        )
        .keyboardType(keyboardType)
        .textInputAutocapitalization(.never)
        .foregroundStyle(Theme.neonYellow)
      }
    }
    .padding()
    .background(Theme.darkGray)
    .cornerRadius(15)
    .overlay(
      RoundedRectangle(cornerRadius: 15)
        .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
    )
  }
}
