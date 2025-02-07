// ContentView.swift
import SwiftUI

struct HomeView: View {

  var body: some View {
    VStack(spacing: 30) {
      switch Manager.shared.currentState {
      case .initial:
        SetupView()
      case .paused:
        PausedView()
      case .countdown:
        CountdownView()
      case .tracking:
        TrackingView()
      case .failed:
        FailureView()
      case .completed:
        CompletionView()
      }
    }
  }
}
