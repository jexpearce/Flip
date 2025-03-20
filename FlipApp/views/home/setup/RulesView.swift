//
//  RulesView.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/24/25.
//

import Foundation
import SwiftUI

struct RulesView: View {
    @Binding var showRules: Bool
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissRules()
                }
            
            // Rules card
            VStack(spacing: 20) {
                // Title
                Text("RULES")
                    .font(.system(size: 36, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .offset(y: 8)
                            .foregroundColor(Theme.orange),
                        alignment: .bottom
                    )
                
                // Subtitle
                Text("True Productivity")
                    .font(.system(size: 16, weight: .bold))
                    .italic()
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 5)
                
                // Rules content in a scrollable area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        RuleSection(
                            number: "01",
                            title: "The Flip",
                            content: "After starting a session, you must physically flip your phone face down before the countdown ends. Keep it face down for the entire duration."
                        )
                        
                        RuleSection(
                            number: "02",
                            title: "Pause Mode",
                            content: "When enabled, you can temporarily flip your phone face up."
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("• You'll have 10 seconds to either pause the session or flip back.")
                                .ruleText()
                            
                            Text("• The pause button appears when you flip your phone up.")
                                .ruleText()
                            
                            Text("• After pausing, you can resume anytime. You'll have 5 seconds to flip your phone back down.")
                                .ruleText()
                            
                            Text("• You can set how many pauses you get per session (0-10), and their duration.")
                                .ruleText()
                                .padding(.bottom, 5)
                        }
                        .padding(.leading, 45)
                        
                        RuleSection(
                            number: "03",
                            title: "Challenge Mode",
                            content: "With pauses disabled, any flip will instantly fail your session. For the disciplined only, but will earn you significantly more points. Ensure you are in Do Not Disturb."
                        )
                        
                        RuleSection(
                            number: "04",
                            title: "Session End",
                            content: "Your session completes when the timer reaches zero. The phone must remain face down until completion."
                        )
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 400)
                
                // Close button
                Button(action: {
                    dismissRules()
                }) {
                    Text("CLOSE")
                        .font(.system(size: 18, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(width: 180, height: 44)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Theme.buttonGradient)
                                
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 30)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.darkGray)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 20)
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
            .frame(maxWidth: 380)
            .offset(y: animateContent ? 0 : 50)
            .opacity(animateContent ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }
        }
        .transition(.opacity)
    }
    
    private func dismissRules() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            animateContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showRules = false
            }
        }
    }
}

struct RuleSection: View {
    let number: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Rule number
            Text(number)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(Theme.orange)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                // Rule title
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // Rule content
                Text(content)
                    .ruleText()
            }
        }
    }
}

extension Text {
    func ruleText() -> some View {
        self
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.8))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}
