import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class WeeklySessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var weeksLongestSession: Int = 0
    private let firebaseManager = FirebaseManager.shared

    func loadSessions(for userId: String) {
        firebaseManager.db.collection("sessions").whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self?.sessions = documents.compactMap { document in
                        try? document.data(as: Session.self)
                    }

                    // Calculate this week's longest session
                    let calendar = Calendar.current
                    let currentDate = Date()
                    let weekStart = calendar.date(
                        from: calendar.dateComponents(
                            [.yearForWeekOfYear, .weekOfYear],
                            from: currentDate
                        )
                    )!

                    let thisWeeksSessions =
                        self?.sessions
                        .filter { session in
                            // Only include successful sessions from this week
                            session.wasSuccessful
                                && calendar.isDate(
                                    session.startTime,
                                    equalTo: weekStart,
                                    toGranularity: .weekOfYear
                                )
                        } ?? []

                    self?.weeksLongestSession =
                        thisWeeksSessions.max(by: { $0.actualDuration < $1.actualDuration })?
                        .actualDuration ?? 0
                }
            }
    }
}
