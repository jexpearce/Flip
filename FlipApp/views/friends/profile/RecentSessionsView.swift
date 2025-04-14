import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct RecentSessionsView: View {
    let user: FirebaseManager.FlipUser
    let weeklyViewModel: WeeklySessionListViewModel
    let cyanBlueGlow: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("RECENT SESSIONS").font(.system(size: 16, weight: .black)).tracking(5)
                .foregroundColor(.white).shadow(color: cyanBlueGlow, radius: 6).padding(.horizontal)

            // Using the WeeklySessionList component
            WeeklySessionList(userId: user.id, viewModel: weeklyViewModel)
        }
    }
}
