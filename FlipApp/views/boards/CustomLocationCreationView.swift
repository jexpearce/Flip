import CoreLocation
import Foundation
import SwiftUI

struct CustomLocationCreationView: View {
    @Binding var isPresented: Bool
    let coordinate: CLLocationCoordinate2D
    let onLocationCreated: (BuildingInfo) -> Void

    @State private var locationName: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Main background
            Theme.creationGradient.edgesIgnoringSafeArea(.all)

            // Decorative element
            VStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.darkRed.opacity(0.15), Theme.darkRuby.opacity(0.05),
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .frame(width: 250, height: 250).offset(x: 150, y: -100).blur(radius: 40)

                Spacer()
            }

            VStack(spacing: 20) {
                // Header with icon and title
                HStack {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 24))
                        .foregroundColor(Theme.darkRed)
                        .shadow(color: Theme.darkRed.opacity(0.5), radius: 4)

                    Text("ADD CUSTOM LOCATION").font(.system(size: 20, weight: .black)).tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Theme.darkRed.opacity(0.5), radius: 8)
                }

                Text("Create a new location at your current position").font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
                    .padding(.bottom, 10)

                // Location name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOCATION NAME").font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(.white.opacity(0.7))

                    TextField("Department of Computer Science, etc.", text: $locationName).padding()
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.silveryGradient5, lineWidth: 1)
                            }
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                // Coordinates display
                VStack(alignment: .leading, spacing: 8) {
                    Text("COORDINATES").font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(.white.opacity(0.7))

                    HStack {
                        Image(systemName: "location.fill").font(.system(size: 16))
                            .foregroundColor(Theme.darkRed).padding(.trailing, 8)

                        Text(
                            "\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))"
                        )
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))

                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3), Color.white.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                }
                .padding(.horizontal)

                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage).font(.system(size: 14)).foregroundColor(Theme.darkRed)
                        .padding(.top, 10)
                }

                // Create button
                Button(action: createLocation) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 24, height: 24)
                        }
                        else {
                            Image(systemName: "plus.circle.fill").font(.system(size: 18))
                        }

                        Text("Create Location").font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white).frame(height: 54).frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            // Button gradient
                            Group {
                                if locationName.isEmpty {
                                    Color.gray.opacity(0.5)
                                }
                                else {
                                    LinearGradient(
                                        colors: [
                                            Theme.darkRed.opacity(0.8),
                                            Theme.darkerRed.opacity(0.8),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }

                            // Glass effect
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))

                            // Edge highlight
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.silveryGradient, lineWidth: 1)
                        }
                    )
                    .shadow(
                        color: locationName.isEmpty ? Color.clear : Theme.darkRed.opacity(0.5),
                        radius: 8
                    )
                    .padding(.horizontal).padding(.top, 15)
                }
                .disabled(locationName.isEmpty || isCreating)

                // Cancel button
                Button(action: { isPresented = false }) {
                    Text("Cancel").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 12).frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 24)
        }
        .frame(maxWidth: 350).cornerRadius(20).shadow(color: Color.black.opacity(0.3), radius: 20)
    }

    private func createLocation() {
        guard !locationName.isEmpty else {
            errorMessage = "Please enter a location name"
            return
        }

        isCreating = true
        errorMessage = nil

        CustomLocationHandler.shared.createCustomLocation(name: locationName, at: coordinate) {
            buildingInfo,
            error in
            DispatchQueue.main.async {
                isCreating = false

                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }

                if let buildingInfo = buildingInfo {
                    onLocationCreated(buildingInfo)
                    isPresented = false
                }
                else {
                    errorMessage = "Failed to create location"
                }
            }
        }
    }
}
