import SwiftUI

struct SimulatorControlView: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        VStack {
            Text("Simulator Controls")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text("Current: \(appManager.isFaceDown ? "Face Down" : "Face Up")")
                .padding(.bottom, 10)
            
            HStack(spacing: 20) {
                Button(action: {
                    appManager.simulateSetFaceDown()
                }) {
                    VStack {
                        Image(systemName: "iphone.gen3.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("Face Down")
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(appManager.isFaceDown ? Color.blue.opacity(0.2) : Color.clear)
                    )
                }
                
                Button(action: {
                    appManager.simulateSetFaceUp()
                }) {
                    VStack {
                        Image(systemName: "iphone.gen3.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                        Text("Face Up")
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(!appManager.isFaceDown ? Color.red.opacity(0.2) : Color.clear)
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
}

#Preview {
    SimulatorControlView()
        .environmentObject(AppManager.shared)
} 