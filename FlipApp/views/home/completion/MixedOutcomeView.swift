import FirebaseAuth
import Foundation
import SwiftUI

struct MixedOutcomeView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showButton = false
    @State private var isButtonPressed = false
    @State private var isGlowing = false

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
        if participantDetails.isEmpty { return "Session completed with mixed results" }

        let successful = participantDetails.filter { $0.wasSuccessful }
        let failed = participantDetails.filter { !$0.wasSuccessful }

        if successful.isEmpty {
            return "All participants failed to complete the session"
        }
        else if failed.isEmpty {
            return "All participants successfully completed the session"
        }
        else {
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
        ScrollView {
            VStack(spacing: 30) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: currentUserSucceeded
                                    ? [
                                        Theme.mutedGreen.opacity(0.3),
                                        Theme.darkerGreen.opacity(0.2),
                                    ]
                                    : [Theme.mutedRed.opacity(0.3), Theme.darkerRed.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 110, height: 110)

                    Image(
                        systemName: currentUserSucceeded
                            ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: currentUserSucceeded
                                ? [Theme.mutedGreen, Theme.darkerGreen]
                                : [Theme.mutedRed, Theme.darkerRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: currentUserSucceeded
                            ? Theme.mutedGreen.opacity(isGlowing ? 0.6 : 0.3)
                            : Theme.mutedRed.opacity(isGlowing ? 0.6 : 0.3),
                        radius: isGlowing ? 15 : 8
                    )
                }
                .scaleEffect(showIcon ? 1 : 0)

                // Title
                Text(currentUserSucceeded ? "YOU SUCCEEDED" : "SESSION FAILED")
                    .font(.system(size: 28, weight: .black)).tracking(6).foregroundColor(.white)
                    .shadow(
                        color: currentUserSucceeded
                            ? Theme.mutedGreen.opacity(0.5) : Theme.mutedRed.opacity(0.5),
                        radius: 8
                    )
                    .offset(y: showTitle ? 0 : 50).opacity(showTitle ? 1 : 0)

                // Results section
                VStack(spacing: 15) {
                    if loadingParticipants {
                        ProgressView().tint(.white).scaleEffect(1.2).padding(.vertical, 15)
                    }
                    else {
                        // Group status message with yellow highlighting
                        Text(completionMessage).font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.yellow).multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Your outcome info
                        if currentUserSucceeded {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(appManager.selectedMinutes)")
                                    .font(.system(size: 50, weight: .black)).foregroundColor(.white)
                                    .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 10)

                                Text("minutes").font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8)).padding(.leading, 4)
                            }

                            Text("of successful focus time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        else {
                            Text("Your phone was moved during the session")
                                .font(.system(size: 18, weight: .medium)).foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            // Calculate actual duration in minutes
                            let actualDuration =
                                (appManager.selectedMinutes * 60 - appManager.remainingSeconds) / 60

                            if actualDuration > 0 {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text("\(actualDuration)")
                                        .font(.system(size: 42, weight: .black))
                                        .foregroundColor(.white)
                                        .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 10)

                                    Text(actualDuration == 1 ? "minute" : "minutes")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8)).padding(.leading, 4)
                                }

                                Text("completed before failure")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        // Participant list
                        if participantDetails.count > 1 {
                            ParticipantListMixed(participants: participantDetails).padding(.top, 15)
                        }
                    }
                }
                .padding(.vertical, 20).padding(.horizontal, 25)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 60 / 255, green: 30 / 255, blue: 110 / 255)
                                            .opacity(0.5),
                                        Color(red: 40 / 255, green: 20 / 255, blue: 80 / 255)
                                            .opacity(0.3),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05))

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10).offset(y: showStats ? 0 : 50)
                .opacity(showStats ? 1 : 0)

                // Back Button
                Button(action: {
                    withAnimation(.spring()) { isButtonPressed = true }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // IMPORTANT: Clear join state explicitly
                        appManager.isJoinedSession = false
                        appManager.liveSessionId = nil
                        appManager.originalSessionStarter = nil
                        appManager.sessionParticipants = []

                        appManager.currentState = .initial
                        isButtonPressed = false
                    }
                }) {
                    Text("RETURN HOME").font(.system(size: 18, weight: .black)).tracking(2)
                        .foregroundColor(.white).frame(height: 56).frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(
                                                    red: 168 / 255,
                                                    green: 85 / 255,
                                                    blue: 247 / 255
                                                ),
                                                Color(
                                                    red: 88 / 255,
                                                    green: 28 / 255,
                                                    blue: 135 / 255
                                                ),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6), Color.white.opacity(0.2),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(
                            color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                .opacity(0.5),
                            radius: 8
                        )
                        .scaleEffect(isButtonPressed ? 0.97 : 1.0)
                }
                .padding(.horizontal, 30).offset(y: showButton ? 0 : 50).opacity(showButton ? 1 : 0)
            }
            .padding(.horizontal, 25).padding(.vertical, 40)
        }
        .onAppear {
            loadParticipantDetails()

            // Stagger animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showIcon = true }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showTitle = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                showStats = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
                showButton = true
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever()) { isGlowing = true }
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
    }

    struct ParticipantListMixed: View {
        let participants: [MixedOutcomeView.ParticipantDetail]

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("PARTICIPANTS").font(.system(size: 14, weight: .bold)).tracking(2)
                    .foregroundColor(Theme.yellow).frame(maxWidth: .infinity, alignment: .center)

                ForEach(participants) { participant in
                    HStack {
                        Text(participant.username).font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        HStack(spacing: 6) {
                            Image(
                                systemName: participant.wasSuccessful
                                    ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundColor(
                                participant.wasSuccessful ? Theme.mutedGreen : Theme.mutedRed
                            )
                            .font(.system(size: 14))

                            Text("\(participant.duration) min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.vertical, 5).padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                }
            }
            .padding(15)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
        }
    }

    private func loadParticipantDetails() {
        guard let sessionId = appManager.liveSessionId else {
            loadingParticipants = false
            return
        }

        FirebaseManager.shared.db.collection("live_sessions").document(sessionId)
            .getDocument { document, error in
                guard let data = document?.data(),
                    let participants = data["participants"] as? [String],
                    let participantStatus = data["participantStatus"] as? [String: String]
                else {
                    loadingParticipants = false
                    return
                }

                // Load user details for each participant
                let group = DispatchGroup()
                var details: [ParticipantDetail] = []

                for participantId in participants {
                    group.enter()

                    FirebaseManager.shared.db.collection("users").document(participantId)
                        .getDocument { userDoc, userError in
                            if let userData = try? userDoc?.data(as: FirebaseManager.FlipUser.self)
                            {
                                let isCompleted =
                                    participantStatus[participantId]
                                    == LiveSessionManager.ParticipantStatus.completed.rawValue
                                let duration = appManager.selectedMinutes

                                details.append(
                                    ParticipantDetail(
                                        id: participantId,
                                        username: userData.username,
                                        wasSuccessful: isCompleted,
                                        duration: duration
                                    )
                                )
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
