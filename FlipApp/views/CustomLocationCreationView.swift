import Foundation
import SwiftUI
import CoreLocation

struct CustomLocationCreationView: View {
    @Binding var isPresented: Bool
    let coordinate: CLLocationCoordinate2D
    let onLocationCreated: (BuildingInfo) -> Void
    
    @State private var locationName: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("ADD CUSTOM LOCATION")
                .font(.system(size: 20, weight: .black))
                .tracking(4)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
            
            Text("Create a new location at your current position")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            // Location name input
            VStack(alignment: .leading, spacing: 8) {
                Text("LOCATION NAME")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Department of Computer Science, etc.", text: $locationName)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            // Coordinates display
            VStack(alignment: .leading, spacing: 8) {
                Text("COORDINATES")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(coordinate.latitude), \(coordinate.longitude)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal)
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            // Create button
            Button(action: createLocation) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                    }
                    
                    Text("Create Location")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if locationName.isEmpty {
                            Color.gray.opacity(0.5)
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .disabled(locationName.isEmpty || isCreating)
            
            // Cancel button
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 12)
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.mainGradient)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        )
        .frame(width: 320)
        .padding()
    }
    
    private func createLocation() {
        guard !locationName.isEmpty else {
            errorMessage = "Please enter a location name"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        CustomLocationHandler.shared.createCustomLocation(name: locationName, at: coordinate) { buildingInfo, error in
            DispatchQueue.main.async {
                isCreating = false
                
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let buildingInfo = buildingInfo {
                    onLocationCreated(buildingInfo)
                    isPresented = false
                } else {
                    errorMessage = "Failed to create location"
                }
            }
        }
    }
}