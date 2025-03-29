import SwiftUI

struct SessionNotesView: View {
    @Binding var sessionTitle: String
    @Binding var sessionNotes: String
    let titleLimit: Int = 10  // Word limit for title
    let notesLimit: Int = 50  // Word limit for notes

    @State private var isTitleFocused: Bool = false
    @State private var isNotesFocused: Bool = false

    private var titleWordCount: Int { sessionTitle.split(separator: " ").count }

    private var notesWordCount: Int { sessionNotes.split(separator: " ").count }

    private var titleRemainingWords: Int { max(0, titleLimit - titleWordCount) }

    private var notesRemainingWords: Int { max(0, notesLimit - notesWordCount) }

    var body: some View {
        VStack(spacing: 15) {
            Text("SESSION NOTES").font(.system(size: 16, weight: .bold)).tracking(2)
                .foregroundColor(Theme.yellow).frame(maxWidth: .infinity, alignment: .center)

            // Title input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Title").font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("\(titleRemainingWords) words left").font(.system(size: 12))
                        .foregroundColor(
                            titleRemainingWords > 0 ? .white.opacity(0.5) : Theme.mutedRed
                        )
                }

                TextField("Add a title (optional)", text: $sessionTitle)
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white).padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isTitleFocused
                                            ? Theme.yellow.opacity(0.5) : Color.white.opacity(0.3),
                                        lineWidth: isTitleFocused ? 1.5 : 1
                                    )
                            )
                    )
                    .onTapGesture {
                        isTitleFocused = true
                        isNotesFocused = false
                    }
                    .onSubmit { isTitleFocused = false }
                    .onChange(of: sessionTitle) {
                        let words = sessionTitle.split(separator: " ")
                        if words.count > titleLimit && words.count > 0 {
                            DispatchQueue.main.async {
                                sessionTitle = words.prefix(titleLimit).joined(separator: " ")
                                if sessionTitle.hasSuffix(" ") { sessionTitle += " " }
                            }
                        }
                    }
            }

            // Notes input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Notes").font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("\(notesRemainingWords) words left").font(.system(size: 12))
                        .foregroundColor(
                            notesRemainingWords > 0 ? .white.opacity(0.5) : Theme.mutedRed
                        )
                }

                ZStack(alignment: .topLeading) {
                    if sessionNotes.isEmpty {
                        Text("Share your thoughts about this session (optional)")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 12).padding(.top, 12)
                    }

                    TextEditor(text: $sessionNotes).font(.system(size: 14)).foregroundColor(.white)
                        .frame(minHeight: 120, maxHeight: 150).padding(3)  // TextEditor has internal padding
                        .background(Color.clear).scrollContentBackground(.hidden)
                        .onTapGesture {
                            isTitleFocused = false
                            isNotesFocused = true
                        }
                        .onChange(of: sessionNotes) {
                            let words = sessionNotes.split(separator: " ")
                            if words.count > notesLimit && words.count > 0 {
                                // Use a small delay to not interfere with typing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    sessionNotes = words.prefix(notesLimit).joined(separator: " ")
                                    if sessionNotes.hasSuffix(" ") { sessionNotes += " " }
                                }
                            }
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isNotesFocused
                                        ? Theme.yellow.opacity(0.5) : Color.white.opacity(0.3),
                                    lineWidth: isNotesFocused ? 1.5 : 1
                                )
                        )
                )
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.mutedPink.opacity(0.4), Theme.deepBlue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8)
        .onTapGesture {
            // This will handle taps on the background to dismiss the keyboard
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        isTitleFocused = false
        isNotesFocused = false
    }
}
