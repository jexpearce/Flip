import SwiftUI
import UIKit

struct ImprovedProfileCropperView: View {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var onCrop: (UIImage) -> Void

    // State for image positioning and scaling
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Fixed crop circle size - using a percentage of screen width for better adaptability
    private var cropSize: CGFloat {
        UIScreen.main.bounds.width * 0.85
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black
                    .edgesIgnoringSafeArea(.all)

                if let image = image {
                    GeometryReader { geo in
                        ZStack {
                            // Container for the image with clipping
                            ZStack {
                                // The image to be cropped
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .frame(
                                        width: geo.size.width,
                                        height: geo.size.height)
                            }
                            .gesture(
                                // Drag gesture for positioning
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width
                                                + value.translation.width,
                                            height: lastOffset.height
                                                + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .gesture(
                                // Pinch gesture for zooming
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        // Apply a more significant zoom effect
                                        let newScale = scale * delta
                                        scale = min(max(newScale, 0.5), 10.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            // Double-tap to reset
                            .onTapGesture(count: 2) {
                                withAnimation(.spring()) {
                                    scale = calculateInitialScale(
                                        image: image, in: geo.size)
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }

                            // Overlay with circle cut-out
                            CropCircleOverlay(
                                size: geo.size, cropSize: cropSize
                            )
                            .allowsHitTesting(false)  // Allow gestures to pass through to the image
                        }
                        .onAppear {
                            scale = calculateInitialScale(
                                image: image, in: geo.size)
                        }
                    }
                } else {
                    Text("No image selected")
                        .foregroundColor(.white)
                }

                // Instructions at the bottom
                VStack {
                    Spacer()

                    Text(
                        "• Drag to position • Pinch to zoom • Double-tap to reset"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Position Your Profile Picture")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let sourceImage = image {
                            let croppedImage = cropImage(sourceImage)
                            onCrop(croppedImage)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }

    // Calculate an appropriate initial scale based on image and screen size
    private func calculateInitialScale(image: UIImage, in size: CGSize)
        -> CGFloat
    {
        let imageSize = image.size
        let screenSize = size

        // Calculate initial scale that makes the image fill the circle
        let initialScale = max(
            cropSize
                / (imageSize.width
                    * min(
                        screenSize.width / imageSize.width,
                        screenSize.height / imageSize.height)),
            cropSize
                / (imageSize.height
                    * min(
                        screenSize.width / imageSize.width,
                        screenSize.height / imageSize.height))
        )

        // Ensure we start with a reasonably zoomed-in view
        return max(initialScale, 1.0) * 1.1  // Add a little extra zoom (10%)
    }

    // Perform the actual cropping of the image
    private func cropImage(_ sourceImage: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: cropSize, height: cropSize))

        return renderer.image { context in
            // Create the crop circle path
            let circlePath = UIBezierPath(
                ovalIn: CGRect(x: 0, y: 0, width: cropSize, height: cropSize))
            circlePath.addClip()

            // Get the actual displayed image size
            let screenSize = UIScreen.main.bounds.size
            let screenScale = min(
                screenSize.width / sourceImage.size.width,
                screenSize.height / sourceImage.size.height)
            let displayedSize = CGSize(
                width: sourceImage.size.width * screenScale * scale,
                height: sourceImage.size.height * screenScale * scale
            )

            // Calculate where to draw the image
            let centerOffsetX =
                (displayedSize.width / 2) - (cropSize / 2) - offset.width
            let centerOffsetY =
                (displayedSize.height / 2) - (cropSize / 2) - offset.height

            // Draw the image
            let drawRect = CGRect(
                x: -centerOffsetX,
                y: -centerOffsetY,
                width: displayedSize.width,
                height: displayedSize.height
            )

            sourceImage.draw(in: drawRect)
        }
    }
}

// Overlay view that creates a transparent circle in an opaque background
struct CropCircleOverlay: View {
    let size: CGSize
    let cropSize: CGFloat

    var body: some View {
        ZStack {
            // Semi-transparent black background
            Rectangle()
                .fill(Color.black.opacity(0.6))

            // Transparent circle
            Circle()
                .frame(width: cropSize, height: cropSize)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(width: size.width, height: size.height)

        // White circle outline for visibility
        Circle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: cropSize, height: cropSize)
    }
}
