//
//  FailureView.swift
//  Flip
//
//  Created by James Pearce on 2/7/25.
//

import SwiftUI

struct FailureView: View {
  @EnvironmentObject var flipManager: Manager

  var body: some View {

    VStack(spacing: 30) {
      Text("Session Failed!")
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundColor(.red)

      Text("Your phone was moved during the session")
        .font(.system(size: 20))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)

      VStack(spacing: 20) {
        Button(action: {
          flipManager.startCountdown()
        }) {
          HStack {
            Text("Try Again")
            Text("(\(flipManager.selectedMinutes) min)")
          }
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.black)
          .frame(width: 250, height: 50)
          .background(Color.white)
          .cornerRadius(25)
        }

        Button(action: {
          flipManager.currentState = .initial
        }) {
          Text("Change Time")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 200, height: 44)
            .background(Color(white: 0.2))
            .cornerRadius(22)
        }
      }
    }
    .padding(.horizontal, 30)
  }
}
