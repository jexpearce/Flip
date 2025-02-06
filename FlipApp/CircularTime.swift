import SwiftUI

struct CircularTime: View {
    @Binding var selectedMinutes: Int
    let timeIntervals = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    @State private var previousValue: Int = 1
    @State private var animationAmount: Double = 0
    
    private let circleSize: CGFloat = 280
    private let dotSize: CGFloat = 12
    
    var body: some View {
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
                .offset(y: -circleSize/2)
                .rotationEffect(.degrees(progressDegrees))
            
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
            .frame(width: circleSize * 0.7, height: circleSize * 0.7) // Made picker larger
        }
        .onChange(of: selectedMinutes) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animationAmount = Double(selectedMinutes)
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
}

