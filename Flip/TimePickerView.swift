// TimePickerView.swift
import SwiftUI

struct TimePickerView: View {
    @Binding var selectedMinutes: Int
    
    let timeIntervals = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    
    var body: some View {
        Picker("Select Duration", selection: $selectedMinutes) {
            ForEach(timeIntervals, id: \.self) { minutes in
                Text("\(minutes) min")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.neonYellow)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(height: 150)
        .compositingGroup()
        .clipped()
    }
}
