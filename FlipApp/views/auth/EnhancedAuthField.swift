import SwiftUI

struct EnhancedAuthField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    let isSelected: Bool
    var accentColor: Color
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .frame(width: 20).scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: accentColor.opacity(0.5), radius: isSelected ? 4 : 0)

            Group {
                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundColor(.white.opacity(0.4))
                    )
                }
                else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundColor(.white.opacity(0.4))
                    )
                    .keyboardType(keyboardType).textInputAutocapitalization(.never)
                }
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.5 : 0.2),
                                Color.white.opacity(isSelected ? 0.2 : 0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        )
        .shadow(color: isSelected ? accentColor.opacity(0.2) : .clear, radius: 4)
        .onTapGesture { onTap() }.animation(.spring(), value: isSelected)
    }
}
