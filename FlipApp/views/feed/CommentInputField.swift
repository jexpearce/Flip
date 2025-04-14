import SwiftUI

struct CommentInputField: View {
    @Binding var comment: String
    @FocusState var isFocused: Bool
    @Binding var showSavedIndicator: Bool
    @Binding var showCommentField: Bool
    var onSubmit: (String) -> Void

    private let maxChars = 100

    var body: some View {
        VStack(spacing: 10) {
            // Break down into smaller components
            commentEditorView
            actionButtonsRow
        }
        .padding(12).background(backgroundView).shadow(color: Color.black.opacity(0.1), radius: 4)
    }

    // MARK: - Subviews

    private var commentEditorView: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if comment.isEmpty { placeholderText }

            // Text editor
            editorField
        }
        .background(editorBackground)
    }

    private var placeholderText: some View {
        Text("Add a comment (100 chars max)...").font(.system(size: 14))
            .foregroundColor(.white.opacity(0.4)).padding(.top, 8).padding(.leading, 8)
            .allowsHitTesting(false)
    }

    private var editorField: some View {
        TextEditor(text: $comment).font(.system(size: 14)).foregroundColor(.white).padding(4)
            .frame(height: 80).focused($isFocused).scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: comment) {
                if comment.count > maxChars { comment = String(comment.prefix(maxChars)) }
            }
    }

    private var editorBackground: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2))

            // Glass effect
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))

            // Highlight on top
            RoundedRectangle(cornerRadius: 10).trim(from: 0, to: 0.5)
                .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180)).padding(1)

            // Focus/active border
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isFocused ? Theme.mutedGreen.opacity(0.6) : Color.white.opacity(0.2),
                    lineWidth: 1
                )
        }
    }

    private var actionButtonsRow: some View {
        HStack {
            characterCounter
            Spacer()
            cancelButton
            submitButton
        }
    }

    private var characterCounter: some View {
        Text("\(comment.count)/\(maxChars)").font(.system(size: 12))
            .foregroundColor(
                comment.count > maxChars * Int(0.8) ? Theme.orange : .white.opacity(0.6)
            )
    }

    private var cancelButton: some View {
        Button(action: {
            isFocused = false
            withAnimation(.spring()) {
                comment = ""  // Clear comment on cancel
                showCommentField = false
            }
            print("Comment cancelled")
        }) {
            Text("Cancel").font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    ZStack {
                        // Base shape
                        Capsule().fill(Color.black.opacity(0.3))

                        // Glass effect
                        Capsule().fill(Color.white.opacity(0.05))

                        // Subtle border
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var submitButton: some View {
        Button(action: {
            isFocused = false
            let currentComment = comment  // Capture current comment
            onSubmit(currentComment)  // Pass the comment
        }) { submitButtonContent }
        .disabled(comment.isEmpty || comment.count > maxChars).opacity(comment.isEmpty ? 0.5 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }

    private var submitButtonContent: some View {
        HStack {
            if showSavedIndicator {
                Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
            }
            else {
                Text("Save").font(.system(size: 14, weight: .medium))
            }
        }
        .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).frame(width: 70)
        .background(submitButtonBackground)
    }

    private var submitButtonBackground: some View {
        ZStack {
            // Base gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Theme.mutedGreen.opacity(0.7), Theme.darkerGreen.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Glass effect
            Capsule().fill(Color.white.opacity(0.1))

            // Highlight on top
            Capsule().trim(from: 0, to: 0.5).fill(Color.white.opacity(0.15))
                .rotationEffect(.degrees(180)).padding(1)

            // Subtle border
            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: Theme.mutedGreen.opacity(0.4), radius: 4)
    }

    private var backgroundView: some View {
        ZStack {
            // Base shape
            RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.3))

            // Glass effect
            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))

            // Highlight on top
            RoundedRectangle(cornerRadius: 14).trim(from: 0, to: 0.5)
                .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180)).padding(1)

            // Subtle border
            RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}
