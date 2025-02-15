//
//  FriendCard.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/9/25.
//

import Foundation
import SwiftUI

struct FriendCard: View {
    let friend: FirebaseManager.FlipUser

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(friend.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .retroGlow()

                Text("\(friend.totalSessions) sessions")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(friend.totalFocusTime) min")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .retroGlow()

                Text("total focus time")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
