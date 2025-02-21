import SwiftUI

struct CircularTime: View {
    @Binding var selectedMinutes: Int
    let timeIntervals = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    @State private var previousValue: Int = 1
    @State private var animationAmount: Double = 0
    @State private var dragAngle: Double = 0
    @GestureState private var isDragging: Bool = false
    private let circleSize: CGFloat = 280
    private let dotSize: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Tick marks
                ForEach(0..<12) { tick in
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 2, height: 15)
                        .offset(y: -circleSize/2 + 15)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }
                
                // Background Circle with gradient
                Circle()
                
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                    
                    .frame(width: circleSize, height: circleSize)

                // Progress Circle with gradient and glow
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.orange.opacity(0.5), radius: 4)

                // Trail effect behind the dot
                if isDragging {
                    Circle()
                        .fill(Theme.orange.opacity(0.3))
                        .frame(width: dotSize * 2, height: dotSize * 2)
                        .blur(radius: 4)
                        .offset(y: -circleSize / 2)
                        .rotationEffect(.degrees(progressDegrees))
                }

                // Moving Dot
                Circle()
                    .fill(Theme.orange)
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: Theme.orange.opacity(0.6), radius: isDragging ? 8 : 4)
                    .offset(y: -circleSize / 2)
                    .rotationEffect(.degrees(progressDegrees))
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .updating($isDragging) { value, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                let center = CGPoint(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height / 2
                                )
                                let vector = CGPoint(
                                    x: value.location.x - center.x,
                                    y: value.location.y - center.y
                                )

                                var angle = atan2(vector.y, vector.x) * 180 / .pi
                                angle = (90 - angle).truncatingRemainder(dividingBy: 360)
                                if angle < 0 { angle += 360 }

                                var minutes = Int((angle / 360.0) * 60.0)
                                minutes = max(1, min(60, minutes))

                                let newMinutes = findClosestInterval(minutes)

                                if newMinutes != selectedMinutes {
                                    withAnimation(.interactiveSpring()) {
                                        selectedMinutes = newMinutes
                                        animationAmount = Double(newMinutes)
                                        // Add haptic feedback
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                }
                            }
                    )
                    .scaleEffect(isDragging ? 1.5 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)

                // Time Display with Picker
                Picker("", selection: $selectedMinutes) {
                    ForEach(timeIntervals, id: \.self) { minutes in
                        HStack(spacing: 4) {
                            Text("\(minutes)")
                                .font(
                                    .system(
                                        size: selectedMinutes == minutes ? 40 : 22,
                                        weight: selectedMinutes == minutes ? .black : .medium,
                                        design: .default
                                    ))
                            Text("minute" + (minutes == 1 ? "" : "s"))
                                .font(
                                    .system(
                                        size: selectedMinutes == minutes ? 16 : 12,
                                        weight: .medium,
                                        design: .default
                                    )
                                )
                                .foregroundColor(.white.opacity(selectedMinutes == minutes ? 0.8 : 0.5))
                        }
                        .foregroundColor(selectedMinutes == minutes ? .white : .white.opacity(0.5))
                        .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: circleSize * 0.7, height: circleSize * 0.7)
                .colorMultiply(Color.white.opacity(0.9))
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: circleSize)
    }

    private var progressValue: Double {
        Double(selectedMinutes) / 60.0
    }

    private var progressDegrees: Double {
        (animationAmount / 60.0) * 360.0
    }

    private func findClosestInterval(_ minutes: Int) -> Int {
        return timeIntervals.min(by: { abs($0 - minutes) < abs($1 - minutes) }) ?? 1
    }
}