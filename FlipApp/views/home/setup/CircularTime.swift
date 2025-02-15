import SwiftUI

struct CircularTime: View {
    @Binding var selectedMinutes: Int
    let timeIntervals = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    
    @State private var rotationAngle: Double = 0 // Tracks the angle of the dot
    @GestureState private var isDragging: Bool = false
    
    private let circleSize: CGFloat = 280
    private let dotSize: CGFloat = 12
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = circleSize / 2
            
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Theme.darkGray, lineWidth: 8)
                    .frame(width: circleSize, height: circleSize)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(Theme.neonYellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                
                // Moving Dot
                Circle()
                    .fill(Theme.neonYellow)
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: Theme.neonYellow.opacity(0.5), radius: 5)
                    .position(calculateDotPosition(center: center, radius: radius, angle: rotationAngle))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isDragging) { value, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                // Calculate the angle between the drag position and the center
                                let location = value.location
                                let vector = CGPoint(
                                    x: location.x - center.x,
                                    y: location.y - center.y
                                )
                                
                                // Calculate the angle in degrees (0-360 range, with 0 at the top)
                                var angle = atan2(vector.y, vector.x) * 180 / .pi
                                angle = (90 - angle).truncatingRemainder(dividingBy: 360)
                                if angle < 0 { angle += 360 }
                                
                                // Update the rotation angle
                                rotationAngle = angle
                                
                                // Convert angle to minutes (0-360 maps to 0-60)
                                let minutes = Int((angle / 360.0) * 60.0)
                                
                                // Snap to the nearest valid interval
                                let newMinutes = findClosestInterval(minutes)
                                if newMinutes != selectedMinutes {
                                    selectedMinutes = newMinutes
                                }
                            }
                    )
                    .scaleEffect(isDragging ? 1.5 : 1.0)
                    .animation(.spring(), value: isDragging)
                
                // Time Selection Wheel
                Picker("", selection: $selectedMinutes) {
                    ForEach(timeIntervals, id: \.self) { minutes in
                        HStack(spacing: 4) {
                            Text("\(minutes)")
                                .font(.system(
                                    size: selectedMinutes == minutes ? 40 : 22,
                                    weight: selectedMinutes == minutes ? .black : .medium,
                                    design: .rounded
                                ))
                            Text("minute" + (minutes == 1 ? "" : "s"))
                                .font(.system(
                                    size: selectedMinutes == minutes ? 16 : 12,
                                    weight: .medium,
                                    design: .rounded
                                ))
                                .foregroundColor(Theme.neonYellow.opacity(selectedMinutes == minutes ? 0.8 : 0.5))
                        }
                        .foregroundColor(selectedMinutes == minutes ? .white : .gray)
                        .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: circleSize * 0.7, height: circleSize * 0.7)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: circleSize)
    }
    
    // MARK: - Helper Functions
    
    private func calculateDotPosition(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        // Convert angle to radians
        let radians = (angle - 90) * .pi / 180
        
        // Calculate the dot's position on the circle's circumference
        let x = center.x + radius * cos(radians)
        let y = center.y + radius * sin(radians)
        
        return CGPoint(x: x, y: y)
    }
    
    private var progressValue: Double {
        Double(selectedMinutes) / 60.0
    }
    
    private func findClosestInterval(_ minutes: Int) -> Int {
        return timeIntervals.min(by: { abs($0 - minutes) < abs($1 - minutes) }) ?? 1
    }
}