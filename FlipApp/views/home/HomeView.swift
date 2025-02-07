// ContentView.swift
import SwiftUI

struct HomeView: View {
  @StateObject private var flipManager = Manager.shared

  var body: some View {
    VStack(spacing: 30) {
      switch flipManager.currentState {
      case .paused:
        pausedView
      case .initial:
        setupView
      case .countdown:
        countdownView
      case .tracking:
        trackingView
      case .failed:
        failureView
      case .completed:
        completionView
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.edgesIgnoringSafeArea(.all))  // Keep this!
  }

  private var failureView: some View {
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

  private var setupView: some View {
    VStack(spacing: 30) {
      // Title with icon
      HStack(spacing: 15) {
        Image(systemName: "arrow.2.squarepath")
          .font(.system(size: 40))
          .foregroundColor(Theme.neonYellow)

        Text("FLIP")
          .font(.system(size: 60, weight: .black, design: .monospaced))
          .tracking(5)
          .foregroundColor(.white)
      }
      .padding(.top, 30)

      // Set Time Title
      Text("SET TIME")
        .font(.system(size: 28, weight: .black, design: .rounded))
        .tracking(4)
        .foregroundColor(Theme.neonYellow)
        .padding(.bottom, -10)

      // Circular Time Picker
      CircularTime(selectedMinutes: $flipManager.selectedMinutes)

      // Settings Controls
      HStack(spacing: 20) {
        // Retries Setting
        ControlButton(
          title: "RETRIES",
          content: {
            Menu {
              Picker("", selection: $flipManager.allowedFlips) {
                Text("NONE").tag(0)
                ForEach(1...5, id: \.self) { number in
                  Text("\(number)").tag(number)
                }
              }
            } label: {
              HStack {
                Text(
                  flipManager.allowedFlips == 0
                    ? "NONE" : "\(flipManager.allowedFlips)"
                )
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.neonYellow)
                Image(systemName: "chevron.down")
                  .font(.system(size: 12, weight: .bold))
                  .foregroundColor(Theme.neonYellow)
              }
            }
          }
        )

        // Pause Toggle
        ControlButton(
          title: "PAUSE",
          content: {
            Toggle("", isOn: $flipManager.allowPause)
              .onChange(of: flipManager.allowPause) {
                if flipManager.allowPause && flipManager.allowedFlips == 0 {
                  flipManager.allowedFlips = 1
                }
              }
              .labelsHidden()
              .tint(Theme.neonYellow)
          }
        )
      }
      .padding(.horizontal)
      .padding(.top, -10)

      // Begin Button
      Button(action: {
        flipManager.startCountdown()
      }) {
        Text("BEGIN")
          .font(.system(size: 24, weight: .black, design: .rounded))
          .tracking(2)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .frame(height: 60)
          .background(
            Theme.neonYellow
              .shadow(color: Theme.neonYellow.opacity(0.5), radius: 10)
          )
          .cornerRadius(30)
      }
      .padding(.horizontal, 40)

      Spacer()
    }
    .background(Theme.mainGradient)
  }

  // Helper view for control buttons
  private struct ControlButton<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
      self.title = title
      self.content = content()
    }

    var body: some View {
      VStack(spacing: 8) {
        Text(title)
          .font(.system(size: 14, weight: .heavy))
          .tracking(1)
          .foregroundColor(Theme.neonYellow.opacity(0.7))

        content
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(Theme.mediumGray)
      .cornerRadius(15)
    }
  }

  private var countdownView: some View {
    VStack(spacing: 25) {
      Text("GET READY")
        .font(.system(size: 24, weight: .heavy))
        .tracking(5)
        .foregroundColor(Theme.neonYellow)

      Text("\(flipManager.countdownSeconds)")
        .font(.system(size: 120, weight: .black))
        .foregroundColor(.white)
        .animation(.spring(), value: flipManager.countdownSeconds)  // This replaces contentTransition
        .scaleEffect(1.2)  // Makes the number slightly larger

      Text("1. LOCK YOUR PHONE")
        .font(.system(size: 20, weight: .heavy))
        .tracking(2)
        .foregroundColor(Theme.neonYellow.opacity(0.7))
      Text("2. FLIP IT OVER!")
        .font(.system(size: 20, weight: .heavy))
        .tracking(2)
        .foregroundColor(Theme.neonYellow.opacity(0.7))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.mainGradient)
  }
  private var pausedView: some View {
    VStack(spacing: 30) {
      Image(systemName: "pause.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(Theme.neonYellow)

      VStack(spacing: 15) {
        Text("Session Paused")
          .font(.title)
          .foregroundColor(.white)

        Text(
          "\(flipManager.pausedRemainingSeconds / 60):\(String(format: "%02d", flipManager.pausedRemainingSeconds % 60)) remaining"
        )
        .font(.system(size: 40, design: .monospaced))
        .foregroundColor(Theme.neonYellow)

        Text("\(flipManager.pausedRemainingFlips) retries left")
          .font(.title3)
          .foregroundColor(.white)
      }

      Button(action: {
        flipManager.startResumeCountdown()
      }) {
        Text("Resume")
          .font(.system(size: 24, weight: .black))
          .foregroundColor(.black)
          .frame(width: 200, height: 50)
          .background(Theme.neonYellow)
          .cornerRadius(25)
      }
    }
    .padding()
    .background(Theme.mainGradient)
  }

  private var completionView: some View {
    VStack(spacing: 30) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(Theme.neonYellow)

      Text("Congratulations!")
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundColor(Theme.neonYellow)

      VStack(spacing: 15) {
        Text("You completed")
          .font(.system(size: 20))
          .foregroundColor(.white)

        Text("\(flipManager.selectedMinutes) minutes")
          .font(.system(size: 40, weight: .bold))
          .foregroundColor(.white)

        Text("of focused time!")
          .font(.system(size: 20))
          .foregroundColor(.white)
      }

      Button(action: {
        flipManager.currentState = .initial
      }) {
        Text("Back to Home")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.black)
          .frame(width: 200, height: 50)
          .background(Color.white)
          .cornerRadius(25)
      }
      .padding(.top, 30)
    }
    .padding(.horizontal, 30)
  }

  private var trackingView: some View {
    VStack(spacing: 30) {
      // Status Icon
      Image(
        systemName: flipManager.isFaceDown
          ? "checkmark.circle.fill" : "xmark.circle.fill"
      )
      .font(.system(size: 60))
      .foregroundColor(flipManager.isFaceDown ? Theme.neonYellow : .red)

      // Status Text
      Text(flipManager.isFaceDown ? "STAY FOCUSED!" : "FLIP YOUR PHONE!")
        .font(.system(size: 32, weight: .heavy))
        .tracking(2)
        .foregroundColor(flipManager.isFaceDown ? Theme.neonYellow : .red)
        .multilineTextAlignment(.center)

      VStack(spacing: 15) {
        if flipManager.isFaceDown {
          Text("REMAINING")
            .font(.system(size: 16, weight: .heavy))
            .tracking(4)
            .foregroundColor(Theme.neonYellow.opacity(0.7))
        }
        Text(flipManager.remainingTimeString)
          .font(.system(size: 50, weight: .heavy))
          .foregroundColor(.white)
          .padding(.horizontal, 40)
          .padding(.vertical, 20)
          .background(
            RoundedRectangle(cornerRadius: 25)
              .fill(Theme.darkGray)
              .overlay(
                RoundedRectangle(cornerRadius: 25)
                  .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
              )
          )
      }
    }

    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.mainGradient)
  }
}
