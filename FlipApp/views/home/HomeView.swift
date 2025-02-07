// ContentView.swift
import SwiftUI

struct HomeView: View {
  @EnvironmentObject var flipManager: Manager

  var body: some View {
    VStack(spacing: 30) {
      switch flipManager.currentState {
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
