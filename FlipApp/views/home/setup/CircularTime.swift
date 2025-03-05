import SwiftUI

struct CircularTime: View {
    @Binding var selectedMinutes: Int
    let timeIntervals = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80, 90, 100, 110, 120]
    private let circleSize: CGFloat = 280
    @State private var rotationProgress: Double = 0
    @State private var isInitialized = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OuterRing()
                TickMarks()
                InnerGradientCircle()
                ProgressIndicator(progressValue: progressValue)
                ProgressDot(progressValue: progressValue, circleSize: circleSize)
                CenterCircle()
                TimePicker(selectedMinutes: $selectedMinutes, timeIntervals: timeIntervals)
                    .onChange(of: selectedMinutes) { newValue in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            rotationProgress = Double(newValue) / 120.0
                        }
                    }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
                if !isInitialized {
                    rotationProgress = Double(selectedMinutes) / 120.0
                    isInitialized = true
                }
            }
        }
        .frame(height: circleSize)
    }

    private var progressValue: Double {
        return rotationProgress
    }
}

// MARK: - Subviews

private struct OuterRing: View {
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.1), lineWidth: 2)
            .frame(width: 280, height: 280)
    }
}

private struct TickMarks: View {
    var body: some View {
        ForEach(0..<60) { tick in
            Group {
                if tick % 5 == 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(y: -280 / 2 + 6)
                        .rotationEffect(.degrees(Double(tick) * 6))
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 6)
                        .offset(y: -280 / 2 + 3)
                        .rotationEffect(.degrees(Double(tick) * 6))
                }
            }
        }
    }
}

private struct InnerGradientCircle: View {
    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Theme.yellow.opacity(0.8),
                        Theme.orange.opacity(0.8),
                        Theme.purple.opacity(0.8),
                        Theme.vibrantPurple.opacity(0.8),
                        Theme.yellow.opacity(0.8)
                    ]),
                    center: .center
                ),
                lineWidth: 6
            )
            .frame(width: 260, height: 260)
            .rotationEffect(.degrees(-90))
    }
}

private struct ProgressIndicator: View {
    let progressValue: Double

    var body: some View {
        Circle()
            .trim(from: 0, to: progressValue)
            .stroke(
                Theme.accentGradient,
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .frame(width: 260, height: 260)
            .rotationEffect(.degrees(-90))
            .shadow(color: Theme.yellowShadow, radius: 4)
    }
}

private struct ProgressDot: View {
    let progressValue: Double
    let circleSize: CGFloat

    var body: some View {
        // Precompute the offset values to simplify the view
        let radius = (circleSize - 20) / 2
        let angle = 2 * .pi * progressValue - .pi / 2
        let xOffset = radius * cos(angle)
        let yOffset = radius * sin(angle)

        return Circle()
            .fill(Theme.yellow)
            .frame(width: 12, height: 12)
            .offset(x: xOffset, y: yOffset)
            .shadow(color: Theme.yellowShadow, radius: 4)
    }
}

private struct CenterCircle: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.05)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 60
                )
            )
            .frame(width: 200, height: 200)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

private struct TimePicker: View {
    @Binding var selectedMinutes: Int
    let timeIntervals: [Int]

    var body: some View {
        VStack(spacing: 4) { // Increase spacing from 0 to 4 to create separation
            Picker("", selection: $selectedMinutes) {
                ForEach(timeIntervals, id: \.self) { minutes in
                    Text("\(minutes)")
                        .font(.system(size: 46, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tag(minutes)
                        .padding(.vertical, 4) // Add padding to increase space between items
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 130, height: 90) // Increased width slightly from 120 to 130
            .compositingGroup()
            .clipped()
            .scaleEffect(1.15) // Slightly reduced scale to maintain overall size

            Text("minutes")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.yellow)
                .padding(.top, 8) // Increased from 5 to 8 to move it down more
        }
        .frame(width: 140, height: 140) // Maintain the same overall size
    }
}