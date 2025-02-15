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
                // Background Circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: circleSize, height: circleSize)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .retroGlow()  // Added here

                // Moving Dot
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .retroGlow()  // Added here
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
                                    y: geometry.size.height / 2)
                                let vector = CGPoint(
                                    x: value.location.x - center.x,
                                    y: value.location.y - center.y
                                )

                                var angle =
                                    atan2(vector.y, vector.x) * 180 / .pi
                                angle = (90 - angle).truncatingRemainder(
                                    dividingBy: 360)
                                if angle < 0 { angle += 360 }

                                var minutes = Int((angle / 360.0) * 60.0)
                                minutes = max(1, min(60, minutes))

                                let newMinutes = findClosestInterval(minutes)
                                if newMinutes != selectedMinutes {
                                    withAnimation(.interactiveSpring()) {
                                        selectedMinutes = newMinutes
                                        animationAmount = Double(newMinutes)
                                    }
                                }
                            }
                    )
                    .scaleEffect(isDragging ? 1.5 : 1.0)

                // Time Display with Picker
                Picker("", selection: $selectedMinutes) {
                    ForEach(timeIntervals, id: \.self) { minutes in
                        HStack(spacing: 4) {
                            Text("\(minutes)")
                                .font(
                                    .system(
                                        size: selectedMinutes == minutes
                                            ? 40 : 22,
                                        weight: selectedMinutes == minutes
                                            ? .black : .medium,
                                        design: .rounded
                                    ))
                            Text("minute" + (minutes == 1 ? "" : "s"))
                                .font(
                                    .system(
                                        size: selectedMinutes == minutes
                                            ? 16 : 12,
                                        weight: .medium,
                                        design: .rounded
                                    )
                                )
                                .foregroundColor(
                                    .gray.opacity(
                                        selectedMinutes == minutes ? 0.8 : 0.5))
                        }
                        .foregroundColor(
                            selectedMinutes == minutes ? .white : .gray
                        )
                        .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: circleSize * 0.7, height: circleSize * 0.7)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: circleSize)
        .onChange(of: selectedMinutes) { _ in
            if !isDragging {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animationAmount = Double(selectedMinutes)
                }
            }
            previousValue = selectedMinutes
        }
    }

    private var progressValue: Double {
        Double(selectedMinutes) / 60.0
    }

    private var progressDegrees: Double {
        (animationAmount / 60.0) * 360.0
    }

    private func findClosestInterval(_ minutes: Int) -> Int {
        return timeIntervals.min(by: { abs($0 - minutes) < abs($1 - minutes) })
            ?? 1
    }
}
