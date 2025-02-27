//
//  SessionNotesView.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/27/25.
//

import Foundation
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
        VStack(spacing: 10) {
            // Section header
            Text("SESSION NOTES")
                .font(.system(size: 18, weight: .black))
                .tracking(5)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
            
            // Title input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Title")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(titleRemainingWords) words left")
                        .font(.system(size: 12))
                        .foregroundColor(titleRemainingWords > 0 ? .white.opacity(0.5) : .red.opacity(0.8))
                }
                
                TextField("", text: $sessionTitle)
                    .placeholder(when: sessionTitle.isEmpty) {
                        Text("Add a title (optional)")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                            
                            if isTitleFocused {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.7),
                                                Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12)
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
                    .onTapGesture {
                        isTitleFocused = true
                        isNotesFocused = false
                    }
            }
            
            // Notes input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Notes")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(notesRemainingWords) words left")
                        .font(.system(size: 12))
                        .foregroundColor(notesRemainingWords > 0 ? .white.opacity(0.5) : .red.opacity(0.8))
                }
                
                ZStack(alignment: .topLeading) {
                    if sessionNotes.isEmpty {
                        Text("Share your thoughts about this session (optional)")
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $sessionNotes)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(height: 70)
                        .padding(2) // Smaller padding for text editor
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1)) // Match title cell background
                        )
                        .onChange(of: sessionNotes) { newValue in
                            // Limit to notesLimit words
                            let words = newValue.split(separator: " ")
                            if words.count > notesLimit {
                                sessionNotes = words.prefix(notesLimit).joined(separator: " ")
                            }
                        }
                        .onTapGesture {
                            isNotesFocused = true
                            isTitleFocused = false
                        }
                }
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                        
                        if isNotesFocused {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.7),
                                            Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.7),
                                Color(red: 16/255, green: 24/255, blue: 57/255).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onTapGesture {
            // Clear focus if tapping outside fields
            isTitleFocused = false
            isNotesFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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