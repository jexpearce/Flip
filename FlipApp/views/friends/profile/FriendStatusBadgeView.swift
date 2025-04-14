import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct FriendStatusBadgeView: View {
    let isFriend: Bool
    let hasSentFriendRequest: Bool

    var body: some View {
        if isFriend {
            FriendStatusBadge(text: "Friends", icon: "person.2.fill", color: Color.green)
        }
        else if hasSentFriendRequest {
            FriendStatusBadge(text: "Friend Request Sent", icon: "clock.fill", color: Color.orange)
        }
    }
}
