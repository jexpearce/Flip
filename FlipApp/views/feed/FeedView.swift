import SwiftUI

struct FeedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced Background Gradient
                Theme.feedGradient.edgesIgnoringSafeArea(.all)

                // Enhanced decorative elements
                VStack {
                    // Top glow effect - brighter and more defined
                    ZStack {
                        // Base large glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.mutedGreen.opacity(0.25),
                                        Theme.mutedGreen.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 250
                                )
                            )
                            .frame(width: 400, height: 400).offset(x: 150, y: -250)

                        // Smaller, more intense center
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.mutedGreen.opacity(0.4),
                                        Theme.mutedGreen.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200).offset(x: 180, y: -220).blur(radius: 20)
                    }

                    Spacer()

                    // Bottom glow effect - enhanced with layered effect
                    ZStack {
                        // Base glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.mutedGreen.opacity(0.15),
                                        Theme.mutedGreen.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 200
                                )
                            )
                            .frame(width: 350, height: 350).offset(x: -150, y: 120)

                        // Secondary glow - creates depth
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.lightTealBlue.opacity(0.12),
                                        Theme.lightTealBlue.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 250, height: 250).offset(x: -180, y: 80).blur(radius: 15)
                    }
                }

                ScrollView {
                    VStack(spacing: 35) {
                        // Enhanced Header with better typography and glow
                        VStack(spacing: 8) {
                            Text("FEED").font(.system(size: 36, weight: .black)).tracking(8)
                                .foregroundColor(.white)
                                .shadow(color: Theme.mutedGreen.opacity(0.7), radius: 15)
                                .padding(.top, 40)
                            Spacer().frame(height: 24)

                            if viewModel.isLoading {
                                // Enhanced loading indicator with glass effect
                                VStack(spacing: 20) {
                                    ZStack {
                                        // Glowing circle behind spinner
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    gradient: Gradient(colors: [
                                                        Theme.mutedGreen.opacity(0.3),
                                                        Theme.mutedGreen.opacity(0.0),
                                                    ]),
                                                    center: .center,
                                                    startRadius: 1,
                                                    endRadius: 50
                                                )
                                            )
                                            .frame(width: 80, height: 80).blur(radius: 10)

                                        // Spinner
                                        ProgressView().scaleEffect(2).tint(Theme.mutedGreen)
                                    }
                                    .padding(.bottom, 5)

                                    // Loading text with animated dots
                                    Text("Loading sessions")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("Please wait while we load your feed")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity).frame(height: 220)
                                .background(
                                    ZStack {
                                        // Glass effect background
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.05))

                                        // Blurred gradient overlay
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.1),
                                                        Color.white.opacity(0.05),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        // Subtle border
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Theme.silveryGradient3, lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                                .padding(.horizontal, 20).padding(.top, 20)
                            }
                            else if viewModel.feedSessions.isEmpty {
                                // Enhanced empty state view
                                EmptyFeedView().padding(.top, 20)
                            }
                            else {
                                // Session cards with subtle spacing improvements
                                ForEach(
                                    Array(viewModel.feedSessions.enumerated()),
                                    id: \.element.id
                                ) { index, session in
                                    FeedSessionCard(session: session, viewModel: viewModel)
                                        .transition(.opacity).padding(.bottom, 16)
                                }
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 20)
                    }
                    .refreshable {
                        print("FeedView refreshed - reloading feed data")
                        viewModel.loadFeed()
                    }
                }
                .onAppear {
                    print("FeedView appeared - loading feed data")
                    viewModel.loadFeed()
                }
                .onDisappear {
                    // Clean up listeners when view disappears to prevent memory leaks
                    print("FeedView disappeared - cleaning up listeners")
                    viewModel.cleanupLikesListeners()
                    viewModel.cleanupCommentsListeners()
                }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage)
                }
                .padding(.top, 20)  // Add padding above the ScrollView
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
