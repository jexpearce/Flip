import Foundation
import SwiftUI
import FirebaseAuth  // Add this import

struct MixedOutcomeView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showButton = false
    @State private var isButtonPressed = false
    
    // State variables for participations
    @State private var participantDetails: [ParticipantDetail] = []
    @State private var loadingParticipants = true
    
    // Current user status
    private var currentUserSucceeded: Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return participantDetails.first(where: { $0.id == userId })?.wasSuccessful ?? false
    }
    
    // Completion info
    private var completionMessage: String {
        if participantDetails.isEmpty {
            return "Session completed with mixed results"
        }
        
        let successful = participantDetails.filter { $0.wasSuccessful }
        let failed = participantDetails.filter { !$0.wasSuccessful }
        
        if successful.isEmpty {
            return "All participants failed to complete the session"
        } else if failed.isEmpty {
            return "All participants successfully completed the session"
        } else {
            return "\(successful.count) completed, \(failed.count) failed"
        }
    }
    
    struct ParticipantDetail: Identifiable {
        let id: String
        let username: String
        let wasSuccessful: Bool
        let duration: Int
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Status icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: currentUserSucceeded ?
                                [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ] :
                                [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .opacity(0.2)
                
                Image(systemName: currentUserSucceeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: currentUserSucceeded ?
                                [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ] :
                                [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: currentUserSucceeded ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 8)
            }
            .scaleEffect(showIcon ? 1 : 0)
            
            // Title
            VStack(spacing: 2) {
                Text(currentUserSucceeded ? "YOU SUCCEEDED" : "SESSION FAILED")
                    .font(.system(size: 24, weight: .black))
                    .tracking(6)
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                
                Text(currentUserSucceeded ? "おめでとう" : "セッション失敗")
                    .font(.system(size: 12))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.7))
            }
            .offset(y: showTitle ? 0 : 50)
            .opacity(showTitle ? 1 : 0)
            
            // Results section
            VStack(spacing: 15) {
                if loadingParticipants {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 10)
                } else {
                    // Group status message
                    Text(completionMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Your outcome info
                    if currentUserSucceeded {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(appManager.selectedMinutes)")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 10)
                            
                            Text("minutes")
                                .font(.system(size: 16))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 4)
                        }
                        
                        Text("of successful focus time")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("Your phone was moved during the session")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            
                        // Calculate actual duration in minutes
                        let actualDuration = (appManager.selectedMinutes * 60 - appManager.remainingSeconds) / 60
                        
                        if actualDuration > 0 {
                            Text("You lasted \(actualDuration) minutes")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Participant list
                    if participantDetails.count > 1 {
                         MOParticipantList(participants: participantDetails)
                             .padding(.top, 10)
                    }
                }
            }
            .offset(y: showStats ? 0 : 50)
            .opacity(showStats ? 1 : 0)
            
            // Back Button
            Button(action: {
                withAnimation(.spring()) {
                    isButtonPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    appManager.currentState = .initial
                    isButtonPressed = false
                }
            }) {
                Text("BACK TO HOME")
                    .font(.system(size: 18, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Theme.buttonGradient)
                            
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 25)
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
                    .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            }
            .offset(y: showButton ? 0 : 50)
            .opacity(showButton ? 1 : 0)
            .padding(.top, 20)
        }
        .padding(.horizontal, 25)
        .onAppear {
            loadParticipantDetails()
            
            // Stagger animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showIcon = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showTitle = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                showStats = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
                showButton = true
            }
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
    }
    struct MOParticipantList: View {
        let participants: [MixedOutcomeView.ParticipantDetail]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("PARTICIPANTS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ForEach(participants) { participant in
                    HStack {
                        Text(participant.username)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: participant.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(participant.wasSuccessful ? .green : .red)
                                .font(.system(size: 12))
                            
                            Text("\(participant.duration) min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private func loadParticipantDetails() {
        guard let sessionId = appManager.liveSessionId else {
            loadingParticipants = false
            return
        }
        
        FirebaseManager.shared.db.collection("live_sessions").document(sessionId).getDocument { document, error in
            guard let data = document?.data(),
                  let participants = data["participants"] as? [String],
                  let participantStatus = data["participantStatus"] as? [String: String] else {
                loadingParticipants = false
                return
            }
            
            // Load user details for each participant
            let group = DispatchGroup()
            var details: [ParticipantDetail] = []
            
            for participantId in participants {
                group.enter()
                
                FirebaseManager.shared.db.collection("users").document(participantId).getDocument { userDoc, userError in
                    if let userData = try? userDoc?.data(as: FirebaseManager.FlipUser.self) {
                        let isCompleted = participantStatus[participantId] == LiveSessionManager.ParticipantStatus.completed.rawValue
                        let duration = appManager.selectedMinutes
                        
                        details.append(ParticipantDetail(
                            id: participantId,
                            username: userData.username,
                            wasSuccessful: isCompleted,
                            duration: duration
                        ))
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.participantDetails = details.sorted { $0.username < $1.username }
                self.loadingParticipants = false
            }
        }
    }
}