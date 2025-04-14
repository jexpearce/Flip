import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct CancelFriendRequestAlert: View {
    @Binding var isPresented: Bool
    let username: String
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Cancel Request").font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Cancel friend request to \(username)?").font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9)).multilineTextAlignment(.center)

                HStack(spacing: 15) {
                    Button("No") { isPresented = false }.foregroundColor(.white)
                        .padding(.vertical, 10).padding(.horizontal, 25)
                        .background(Color.gray.opacity(0.3)).cornerRadius(10)

                    Button("Yes") {
                        onConfirm()
                        isPresented = false
                    }
                    .foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 25)
                    .background(Color.red.opacity(0.7)).cornerRadius(10)
                }
            }
            .padding(25).background(Theme.midnightNavy).cornerRadius(15).shadow(radius: 10)
            .padding(30)
        }
    }
}
