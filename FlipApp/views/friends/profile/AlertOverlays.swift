import SwiftUI

struct AlertOverlays: View {
    @Binding var showRemoveFriendAlert: Bool
    @Binding var showCancelRequestAlert: Bool
    @Binding var showAddFriendConfirmation: Bool
    let user: FirebaseManager.FlipUser
    let friendManager: FriendManager
    let searchManager: SearchManager
    @Binding var friendRequestSent: Bool
    let cancelFriendRequest: (String) -> Void
    let presentationMode: Binding<PresentationMode>

    var body: some View {
        ZStack {
            if showRemoveFriendAlert {
                RemoveFriendAlert(isPresented: $showRemoveFriendAlert, username: user.username) {
                    // Handle friend removal
                    friendManager.removeFriend(friendId: user.id)
                    // Navigate back after removing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }

            if showCancelRequestAlert {
                CancelFriendRequestAlert(
                    isPresented: $showCancelRequestAlert,
                    username: user.username
                ) {
                    // Handle canceling the friend request
                    cancelFriendRequest(user.id)

                    // Update local state
                    friendRequestSent = false
                }
            }

            if showAddFriendConfirmation {
                AddFriendConfirmation(
                    isPresented: $showAddFriendConfirmation,
                    username: user.username
                ) {
                    // Send friend request
                    searchManager.sendFriendRequest(to: user.id)
                    friendRequestSent = true
                }
            }
        }
    }
}
