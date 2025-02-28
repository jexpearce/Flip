import SwiftUI
struct FeedSessionCard: View {
    let session: Session
    
    private var statusColor: LinearGradient {
        session.wasSuccessful ?
            LinearGradient(
                colors: [
                    Color(red: 34/255, green: 197/255, blue: 94/255),
                    Color(red: 22/255, green: 163/255, blue: 74/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            ) :
            LinearGradient(
                colors: [
                    Color(red: 239/255, green: 68/255, blue: 68/255),
                    Color(red: 185/255, green: 28/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
    }
    
    private var hasContent: Bool {
        return session.sessionTitle != nil || session.sessionNotes != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 40, height: 40)
                        .opacity(0.2)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.username)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                    Text(session.formattedStartTime)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Status Icon with enhanced styling - made larger
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 44, height: 44)
                        .opacity(0.8)
                    
                    Image(systemName: session.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .shadow(color: session.wasSuccessful ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 4)
                }
            }

            // Session duration info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(session.duration) min session")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                if !session.wasSuccessful {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text("Lasted \(session.actualDuration) min")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Session title and notes if available - REDUCED PADDING
            if hasContent {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 2) // Reduced vertical padding
                
                VStack(alignment: .leading, spacing: 6) { // Reduced spacing
                    // Session Title if available
                    if let title = session.sessionTitle, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 16, weight: .bold)) // Slightly smaller text
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
                            .lineLimit(2)
                    }
                    
                    // Session Notes if available
                    if let notes = session.sessionNotes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3) // One fewer line to save space
                    }
                }
                .padding(.horizontal, 3) // Minimal horizontal padding
            }
        }
        .padding(.vertical, 16) // Consistent vertical padding
        .padding(.horizontal, 16)
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
    }
}