//
//  ScoreManager.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/24/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class ScoreManager: ObservableObject {
    static let shared = ScoreManager()
    
    // Score constants
    private let initialScore: Double = 3.0
    private let maxScore: Double = 300.0
    private let minScore: Double = 0.0
    
    // Multipliers
    private let noPauseMultiplier: Double = 1.5    // Sessions without pause option are worth more
    private let failurePenaltyMultiplier: Double = 2.0  // Failures are heavily penalized
    private let noPauseFailureReduction: Double = 0.8   // Failures without pause have slightly reduced penalty
    
    // Base points (will be multiplied by session duration and other factors)
    private let baseSuccessPoints: Double = 0.005  // Base points for 1-minute successful session (halved)
    private let baseFailurePoints: Double = 0.025  // Base points deducted for failure (halved)
    
    // Duration scaling factors for non-linear growth based on session length
    private let durationScalingFactor: Double = 1.2  // Exponential growth factor
    
    // Threshold below which sessions earn minimal points (to prevent spamming short sessions)
    private let minEffectiveSessionDuration: Int = 5  // Minutes
    
    @Published private(set) var currentScore: Double = 3.0
    @Published private(set) var scoreHistory: [ScoreChange] = []
    
    private let db = Firestore.firestore()
    
    // Initialize and load score from Firebase
    init() {
        loadScore()
    }
    
    // Calculate points for a completed session
    func processSession(duration: Int, wasSuccessful: Bool, actualDuration: Int, pausesEnabled: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var pointChange: Double = 0
        var reason: String
        
        if wasSuccessful {
            // For successful sessions, calculate points based on duration
            // Use the actual duration to calculate the value
            
            // Apply duration scaling function - longer sessions earn more per minute
            let effectiveDuration = max(actualDuration - minEffectiveSessionDuration, 0)
            let durationFactor = pow(Double(effectiveDuration), durationScalingFactor) / 100.0 + 1.0
            
            // Calculate base points
            pointChange = baseSuccessPoints * Double(actualDuration) * durationFactor
            
            // Apply no-pause multiplier if pauses were disabled
            if !pausesEnabled {
                pointChange *= noPauseMultiplier
                reason = "Completed \(actualDuration)min session (no pauses)"
            } else {
                reason = "Completed \(actualDuration)min session"
            }
        } else {
            // For failed sessions, apply a penalty
            let failurePenalty = baseFailurePoints * Double(duration)
            
            // Apply penalty reduction if no pauses were enabled (acknowledging the higher difficulty)
            if !pausesEnabled {
                pointChange = -failurePenalty * noPauseFailureReduction
                reason = "Failed \(duration)min session (no pauses)"
            } else {
                pointChange = -failurePenalty * failurePenaltyMultiplier
                reason = "Failed \(duration)min session"
            }
        }
        
        // Apply point change to current score
        let oldScore = currentScore
        currentScore = min(maxScore, max(minScore, currentScore + pointChange))
        
        // Create record for history
        let scoreChange = ScoreChange(
            date: Date(),
            oldScore: oldScore,
            newScore: currentScore,
            change: pointChange,
            reason: reason
        )
        
        // Add to local history
        scoreHistory.insert(scoreChange, at: 0)
        
        // Save to Firebase
        saveScore(userId: userId, score: currentScore, scoreChange: scoreChange)
    }
    
    // Load score from Firebase
    private func loadScore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Default to initial score if not logged in
            currentScore = initialScore
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document, document.exists, let data = document.data() {
                if let score = data["score"] as? Double {
                    DispatchQueue.main.async {
                        self.currentScore = score
                    }
                } else {
                    // Initialize score if not present
                    DispatchQueue.main.async {
                        self.currentScore = self.initialScore
                        self.saveScore(userId: userId, score: self.initialScore, scoreChange: nil)
                    }
                }
                
                // Load score history
                self.loadScoreHistory(userId: userId)
            } else {
                // User document doesn't exist yet
                DispatchQueue.main.async {
                    self.currentScore = self.initialScore
                }
            }
        }
    }
    
    // Load score history from Firebase
    private func loadScoreHistory(userId: String) {
        db.collection("users").document(userId).collection("scoreHistory")
            .order(by: "date", descending: true)
            .limit(to: 50)  // Limit to recent history
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                let history = documents.compactMap { document -> ScoreChange? in
                    let data = document.data()
                    
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let oldScore = data["oldScore"] as? Double,
                          let newScore = data["newScore"] as? Double,
                          let change = data["change"] as? Double,
                          let reason = data["reason"] as? String else {
                        return nil
                    }
                    
                    return ScoreChange(
                        id: document.documentID,
                        date: date,
                        oldScore: oldScore,
                        newScore: newScore,
                        change: change,
                        reason: reason
                    )
                }
                
                DispatchQueue.main.async {
                    self.scoreHistory = history
                }
            }
    }
    
    // Save score to Firebase
    private func saveScore(userId: String, score: Double, scoreChange: ScoreChange?) {
        // Update the user's current score
        db.collection("users").document(userId).updateData([
            "score": score
        ]) { error in
            if let error = error {
                print("Error updating score: \(error.localizedDescription)")
            }
        }
        
        // Add to score history if there's a change to record
        if let scoreChange = scoreChange {
            let historyData: [String: Any] = [
                "date": Timestamp(date: scoreChange.date),
                "oldScore": scoreChange.oldScore,
                "newScore": scoreChange.newScore,
                "change": scoreChange.change,
                "reason": scoreChange.reason
            ]
            
            db.collection("users").document(userId).collection("scoreHistory")
                .addDocument(data: historyData) { error in
                    if let error = error {
                        print("Error saving score history: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    // Get rank name based on current score
    func getCurrentRank() -> (name: String, color: Color) {
        switch currentScore {
            case 0.0..<30.0:
                return ("Novice", Color(red: 156/255, green: 163/255, blue: 175/255)) // Gray
            case 30.0..<60.0:
                return ("Apprentice", Color(red: 96/255, green: 165/255, blue: 250/255)) // Light blue
            case 60.0..<90.0:
                return ("Beginner", Color(red: 59/255, green: 130/255, blue: 246/255)) // Blue
            case 90.0..<120.0:
                return ("Steady", Color(red: 16/255, green: 185/255, blue: 129/255)) // Green
            case 120.0..<150.0:
                return ("Focused", Color(red: 245/255, green: 158/255, blue: 11/255)) // Amber
            case 150.0..<180.0:
                return ("Disciplined", Color(red: 249/255, green: 115/255, blue: 22/255)) // Orange
            case 180.0..<210.0:
                return ("Resolute", Color(red: 239/255, green: 68/255, blue: 68/255)) // Red
            case 210.0..<240.0:
                return ("Master", Color(red: 236/255, green: 72/255, blue: 153/255)) // Pink
            case 240.0..<270.0:
                return ("Guru", Color(red: 139/255, green: 92/255, blue: 246/255)) // Purple
            case 270.0...300.0:
                return ("Enlightened", Color(red: 217/255, green: 70/255, blue: 239/255)) // Fuchsia
            default:
                return ("Unranked", Color.gray)
        }
    }
    
    // Helper to calculate how many points needed for next rank
    func pointsToNextRank() -> Double? {
        let ranks = [30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0]
        let current = currentScore
        
        for rank in ranks {
            if current < rank {
                return rank - current
            }
        }
        
        return nil // Already at max rank
    }
    
    // Reset score to initial value (for testing)
    func resetScore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        currentScore = initialScore
        saveScore(userId: userId, score: initialScore, scoreChange: nil)
    }
}

// Model for recording score changes
struct ScoreChange: Identifiable {
    var id: String = UUID().uuidString
    let date: Date
    let oldScore: Double
    let newScore: Double
    let change: Double
    let reason: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isPositive: Bool {
        return change > 0
    }
}

// SwiftUI Color extension for Firestore compatibility
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            return (0, 0, 0, 0)
        }
        
        return (Double(r), Double(g), Double(b), Double(o))
    }
}