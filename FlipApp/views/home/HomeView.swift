// ContentView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        VStack(spacing: 30) {
            switch appManager.currentState {
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
