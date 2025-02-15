import FirebaseAuth
import SwiftUI

struct FlipTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(Theme.darkGray)
            .cornerRadius(15)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Theme.lightGray.opacity(0.3), lineWidth: 1)
            )
    }
}
