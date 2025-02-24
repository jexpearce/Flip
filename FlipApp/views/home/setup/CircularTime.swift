import SwiftUI

struct CircularTime: View {
    @Binding var selectedMinutes: Int
    let timeIntervals = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    private let circleSize: CGFloat = 280
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Tick marks
                ForEach(0..<12) { tick in
                    Rectangle()
                        .fill(Color.white.opacity(0.4)) // Increased opacity
                        .frame(width: 2, height: 15)
                        .offset(y: -circleSize/2 + 15)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }
                
                // Background Circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8) // Increased opacity
                    .frame(width: circleSize, height: circleSize)

                // Progress Circle with gradient and glow
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8), // Increased opacity
                                Color.white.opacity(0.5)  // Increased opacity
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.orange.opacity(0.7), radius: 6) // Enhanced glow

                // Time Display with Picker - Enhanced
                Picker("", selection: $selectedMinutes) {
                    ForEach(timeIntervals, id: \.self) { minutes in
                        HStack(spacing: 6) {
                            Text("\(minutes)")
                                .font(
                                    .system(
                                        size: selectedMinutes == minutes ? 42 : 24,
                                        weight: selectedMinutes == minutes ? .black : .semibold,
                                        design: .rounded // Changed font design
                                    ))
                            Text("minute" + (minutes == 1 ? "" : "s"))
                                .font(
                                    .system(
                                        size: selectedMinutes == minutes ? 18 : 14,
                                        weight: .medium,
                                        design: .rounded // Changed font design
                                    )
                                )
                                .foregroundColor(.white.opacity(selectedMinutes == minutes ? 1.0 : 0.7)) // Increased opacity
                        }
                        .foregroundColor(.white) // Fully opaque for selected and non-selected items
                        .tag(minutes)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: circleSize * 0.8, height: circleSize * 0.7) // Slightly wider
                .compositingGroup()
                .brightness(0.1) // Subtle brightness increase
                
                // Current time indicator
                VStack {
                    Text("\(selectedMinutes)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Theme.orange.opacity(0.7), radius: 6)
                    
                    Text("minutes")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, -10)
                }
                .offset(y: -circleSize * 0.4) // Position above the picker
                .opacity(0) // Hidden by default, since we're using the picker's display
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: circleSize)
    }

    private var progressValue: Double {
        Double(selectedMinutes) / 60.0
    }
}