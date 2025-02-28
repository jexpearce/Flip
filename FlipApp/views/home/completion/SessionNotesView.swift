import SwiftUI

struct SessionNotesView: View {
    @Binding var sessionTitle: String
    @Binding var sessionNotes: String
    let titleLimit: Int = 10  // Word limit for title
    let notesLimit: Int = 50  // Word limit for notes
    
    @State private var isTitleFocused: Bool = false
    @State private var isNotesFocused: Bool = false
    
    private var titleWordCount: Int {
        sessionTitle.split(separator: " ").count
    }
    
    private var notesWordCount: Int {
        sessionNotes.split(separator: " ").count
    }
    
    private var titleRemainingWords: Int {
        max(0, titleLimit - titleWordCount)
    }
    
    private var notesRemainingWords: Int {
        max(0, notesLimit - notesWordCount)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Section header
            Text("SESSION NOTES")
                .font(.system(size: 16, weight: .bold))
                .tracking(3)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                .padding(.bottom, 0)
            
            // Title input
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(titleRemainingWords) words left")
                        .font(.system(size: 10))
                        .foregroundColor(titleRemainingWords > 0 ? .white.opacity(0.5) : .red.opacity(0.8))
                }
                
                TextField("", text: $sessionTitle)
                    .placeholder(when: sessionTitle.isEmpty) {
                        Text("Add a title (optional)")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                            
                            if isTitleFocused {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.7),
                                                Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                        }
                    )
                    .onChange(of: sessionTitle) { newValue in
                        // Limit to titleLimit words
                        let words = newValue.split(separator: " ")
                        if words.count > titleLimit {
                            sessionTitle = words.prefix(titleLimit).joined(separator: " ")
                        }
                    }
                    // Use standard onFocus and blur behavior
            }
            
            // Notes input
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Notes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(notesRemainingWords) words left")
                        .font(.system(size: 10))
                        .foregroundColor(notesRemainingWords > 0 ? .white.opacity(0.5) : .red.opacity(0.8))
                }
                
                ZStack(alignment: .topLeading) {
                    if sessionNotes.isEmpty {
                        Text("Share your thoughts about this session (optional)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                    
                    // Use a standard TextField for better keyboard handling
                    TextEditor(text: $sessionNotes)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(height: 60)
                        .scrollContentBackground(.hidden) // iOS 16+ hide default background
                        .background(Color.clear) // Use clear background
                        .onChange(of: sessionNotes) { newValue in
                            // Limit to notesLimit words
                            let words = newValue.split(separator: " ")
                            if words.count > notesLimit {
                                sessionNotes = words.prefix(notesLimit).joined(separator: " ")
                            }
                        }
                }
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                        
                        if isNotesFocused {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.7),
                                            Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    }
                )
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.6),
                                Color(red: 16/255, green: 24/255, blue: 57/255).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        // Better keyboard dismissal
        .onTapGesture {
            hideKeyboard()
        }
        // Use focus state for better iOS focus handling
        .onAppear {
            // Set focus state handlers
            NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: nil, queue: .main) { _ in
                isTitleFocused = true
                isNotesFocused = false
            }
            NotificationCenter.default.addObserver(forName: UITextView.textDidBeginEditingNotification, object: nil, queue: .main) { _ in
                isTitleFocused = false
                isNotesFocused = true
            }
        }
    }
    
    // Helper to dismiss keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isTitleFocused = false
        isNotesFocused = false
    }
}

// Helper extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}