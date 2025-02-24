//
//  ScoreComponents.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/24/25.
//

import Foundation
import SwiftUI

struct DisciplineRankCard: View {
    @ObservedObject var scoreManager: ScoreManager
    @State private var showScoreHistory = false
    @State private var isButtonPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Rank Display
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISCIPLINE RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.7))
                    
                    let rank = scoreManager.getCurrentRank()
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(rank.name)
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(rank.color)
                            .shadow(color: rank.color.opacity(0.5), radius: 6)
                        
                        Text("\(String(format: "%.1f", scoreManager.currentScore))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Progress to next rank
                if let pointsToNext = scoreManager.pointsToNextRank() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("NEXT RANK")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("\(String(format: "%.1f", pointsToNext))")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                        
                        Text("points needed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            // View Score History Button
            Button(action: {
                withAnimation(.spring()) {
                    isButtonPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isButtonPressed = false
                    showScoreHistory = true
                }
            }) {
                HStack {
                    Text("VIEW SCORE HISTORY")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                )
                .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Theme.buttonGradient)
                    .opacity(0.15)
                
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
        .sheet(isPresented: $showScoreHistory) {
            ScoreHistoryView()
        }
    }
}

struct RankCircle: View {
    let score: Double
    
    private var rankColor: Color {
        ScoreManager.shared.getCurrentRank().color
    }
    
    private var progress: Double {
        // Calculate progress within current rank (0.0 to 1.0)
        let ranks = [0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0]
        
        // Find current rank range
        var rankIndex = 0
        for (index, rankValue) in ranks.enumerated() {
            if score < rankValue {
                rankIndex = index - 1
                break
            }
        }
        
        // If we're at max rank
        if rankIndex == -1 || rankIndex >= ranks.count - 1 {
            return 1.0
        }
        
        // Calculate progress between ranks
        let currentRankValue = ranks[rankIndex]
        let nextRankValue = ranks[rankIndex + 1]
        let progress = (score - currentRankValue) / (nextRankValue - currentRankValue)
        
        return min(1.0, max(0.0, progress))
    }
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 6)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    rankColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: rankColor.opacity(0.5), radius: 4)
            
            // Score Text
            Text(String(format: "%.0f", score))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct ScoreHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var scoreManager = ScoreManager.shared
    @State private var showScoreInfo = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    let rank = scoreManager.getCurrentRank()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DISCIPLINE SCORE")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(rank.name)
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(rank.color)
                                .shadow(color: rank.color.opacity(0.5), radius: 6)
                            
                            Text("\(String(format: "%.1f", scoreManager.currentScore))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal)
                
                // Rank Progress
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        // Background progress bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 16)
                        
                        // Rank segments
                        HStack(spacing: 0) {
                            ForEach(0..<10) { i in
                                RankSegment(rankIndex: i, score: scoreManager.currentScore)
                            }
                        }
                        .frame(height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Rank labels
                    HStack(spacing: 0) {
                        ForEach(0..<10) { i in
                            Text("\(i*30)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Info Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("ABOUT THE SCORE SYSTEM")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("The FLIP scoring system rewards discipline and focus. Longer sessions and disabling pauses earn more points, while failures result in penalties.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: {
                        showScoreInfo = true
                    }) {
                        Text("View detailed scoring information")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.lightTealBlue)
                            .underline()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal)
                
                // Score History List
                VStack(alignment: .leading, spacing: 10) {
                    Text("SCORE HISTORY")
                        .font(.system(size: 16, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if scoreManager.scoreHistory.isEmpty {
                        Text("No score changes recorded yet")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ScrollView {
                            VStack(spacing: 2) {
                                ForEach(scoreManager.scoreHistory) { change in
                                    ScoreHistoryRow(change: change)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showScoreInfo) {
            ScoreInfoView()
        }
    }
}

struct RankSegment: View {
    let rankIndex: Int
    let score: Double
    
    private var segmentColor: Color {
        let rankScore = min(max(0, Double(rankIndex * 30)), 270)
        return getRankColor(for: rankScore)
    }
    
    private var isCurrentRank: Bool {
        let lowerBound = Double(rankIndex * 30)
        let upperBound = Double((rankIndex + 1) * 30)
        return score >= lowerBound && score < upperBound
    }
    
    private var progress: CGFloat {
        if !isCurrentRank {
            return score > Double(rankIndex * 30) ? 1.0 : 0.0
        }
        
        let lowerBound = Double(rankIndex * 30)
        return CGFloat((score - lowerBound) / 30.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Filled portion
                Rectangle()
                    .fill(segmentColor)
                    .frame(width: geometry.size.width * progress)
                
                // Add divider line
                if rankIndex > 0 {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 1)
                        .offset(x: -0.5)
                }
            }
        }
    }
    
    private func getRankColor(for score: Double) -> Color {
        switch score {
            case 0.0..<30.0:
                return Color(red: 156/255, green: 163/255, blue: 175/255) // Gray
            case 30.0..<60.0:
                return Color(red: 96/255, green: 165/255, blue: 250/255) // Light blue
            case 60.0..<90.0:
                return Color(red: 59/255, green: 130/255, blue: 246/255) // Blue
            case 90.0..<120.0:
                return Color(red: 16/255, green: 185/255, blue: 129/255) // Green
            case 120.0..<150.0:
                return Color(red: 245/255, green: 158/255, blue: 11/255) // Amber
            case 150.0..<180.0:
                return Color(red: 249/255, green: 115/255, blue: 22/255) // Orange
            case 180.0..<210.0:
                return Color(red: 239/255, green: 68/255, blue: 68/255) // Red
            case 210.0..<240.0:
                return Color(red: 236/255, green: 72/255, blue: 153/255) // Pink
            case 240.0..<270.0:
                return Color(red: 139/255, green: 92/255, blue: 246/255) // Purple
            case 270.0...300.0:
                return Color(red: 217/255, green: 70/255, blue: 239/255) // Fuchsia
            default:
                return Color.gray
        }
    }
}


struct ScoreHistoryRow: View {
    let change: ScoreChange
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                // Change indicator
                Circle()
                    .fill(change.isPositive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 3) {
                    // Reason
                    Text(change.reason)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Date and score
                    HStack(spacing: 8) {
                        Text(change.formattedDate)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(change.isPositive ? "+\(String(format: "%.2f", change.change))" : "\(String(format: "%.2f", change.change))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(change.isPositive ? Color.green : Color.red)
                    }
                }
                
                Spacer()
                
                // New score
                Text("\(String(format: "%.1f", change.newScore))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 10)
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}

struct ScoreInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                contentStack
            }
        }
    }
    
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            overviewSection
            ranksSection
            pointsSystemSection
            philosophySection
        }
        .padding()
    }
    
    private var headerSection: some View {
        HStack {
            Text("FLIP SCORING SYSTEM")
                .font(.system(size: 24, weight: .black))
                .tracking(2)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.bottom, 20)
    }
    
    private var overviewSection: some View {
        Group {
            Text("Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("The FLIP scoring system rewards discipline and focus. Everyone starts at 3.0 with a maximum of 300.0. Longer sessions and disabling pauses earn more points, while failures result in significant penalties.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 10)
        }
    }
    
    private var ranksSection: some View {
        Group {
            Text("Ranks")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                ForEach(0..<10) { i in
                    rankRow(index: i)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private func rankRow(index: Int) -> some View {
        let baseScore = Double(index) * 30.0
        let rank = getRank(for: baseScore + 15.0)
        
        return HStack {
            Circle()
                .fill(rank.color)
                .frame(width: 16, height: 16)
            
            Text(rank.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(Int(baseScore))-\(Int(baseScore + 30))")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 5)
    }
    
    private var pointsSystemSection: some View {
        Group {
            Text("Points System")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            successfulSessionsSection
            
            failedSessionsSection
        }
    }
    
    private var successfulSessionsSection: some View {
        Group {
            Text("Examples of points earned for successful sessions:")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 8) {
                makeExampleRow(label: "25min with pauses:", value: "+0.44", isPositive: true)
                makeExampleRow(label: "25min without pauses:", value: "+0.66", isPositive: true)
                makeExampleRow(label: "60min with pauses:", value: "+2.08", isPositive: true)
                makeExampleRow(label: "60min without pauses:", value: "+3.12", isPositive: true)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var failedSessionsSection: some View {
        Group {
            Text("Examples of points lost for failed sessions:")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                makeExampleRow(label: "25min with pauses:", value: "-1.25", isPositive: false)
                makeExampleRow(label: "25min without pauses:", value: "-0.50", isPositive: false)
                makeExampleRow(label: "60min with pauses:", value: "-3.00", isPositive: false)
                makeExampleRow(label: "60min without pauses:", value: "-1.20", isPositive: false)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var philosophySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Philosophy")
                .font(.system(size: 20, weight: .regular)).bold()
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("This system embodies the Lee Kuan Yew approach to productivity - strict, challenging, but fair. True discipline is rewarded, while failures have significant consequences.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Text("The path to Enlightened is long and requires consistent discipline over time.")
                .font(.system(size: 16, weight: .regular)).italic()
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 10)
        }
    }
    
    private func makeExampleRow(label: String, value: String, isPositive: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isPositive ? .green : .red)
        }
    }
    
    private func getRank(for score: Double) -> (name: String, color: Color) {
        // First determine the rank name
        let rankName = getRankName(for: score)
        
        // Then get the color for the rank
        let rankColor = getRankColor(for: score)
        
        return (rankName, rankColor)
    }
    
    private func getRankName(for score: Double) -> String {
        switch score {
            case 0.0..<30.0: return "Novice"
            case 30.0..<60.0: return "Apprentice"
            case 60.0..<90.0: return "Beginner"
            case 90.0..<120.0: return "Steady"
            case 120.0..<150.0: return "Focused"
            case 150.0..<180.0: return "Disciplined"
            case 180.0..<210.0: return "Resolute"
            case 210.0..<240.0: return "Master"
            case 240.0..<270.0: return "Guru"
            case 270.0...300.0: return "Enlightened"
            default: return "Unranked"
        }
    }
    
    private func getRankColor(for score: Double) -> Color {
        switch score {
            case 0.0..<30.0: return Color(red: 156/255, green: 163/255, blue: 175/255)
            case 30.0..<60.0: return Color(red: 96/255, green: 165/255, blue: 250/255)
            case 60.0..<90.0: return Color(red: 59/255, green: 130/255, blue: 246/255)
            case 90.0..<120.0: return Color(red: 16/255, green: 185/255, blue: 129/255)
            case 120.0..<150.0: return Color(red: 245/255, green: 158/255, blue: 11/255)
            case 150.0..<180.0: return Color(red: 249/255, green: 115/255, blue: 22/255)
            case 180.0..<210.0: return Color(red: 239/255, green: 68/255, blue: 68/255)
            case 210.0..<240.0: return Color(red: 236/255, green: 72/255, blue: 153/255)
            case 240.0..<270.0: return Color(red: 139/255, green: 92/255, blue: 246/255)
            case 270.0...300.0: return Color(red: 217/255, green: 70/255, blue: 239/255)
            default: return Color.gray
        }
    }
}
// Helper extension for optional SwiftUI modifiers
extension View {
    // Helper to extract common modifiers for section titles
    func sectionTitle() -> some View {
        self
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
    
    // Helper to extract common modifiers for section text
    func sectionText() -> some View {
        self
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.8))
            .padding(.bottom, 10)
    }
}