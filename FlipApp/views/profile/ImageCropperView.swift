import SwiftUI
import UIKit

struct MovableCircleCropperView: View {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var onCrop: (UIImage) -> Void
    
    @State private var cropPosition: CGPoint
    @State private var lastPosition: CGPoint
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    private let cropSize: CGFloat = 250
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    init(image: Binding<UIImage?>, isPresented: Binding<Bool>, onCrop: @escaping (UIImage) -> Void) {
        self._image = image
        self._isPresented = isPresented
        self.onCrop = onCrop
        
        // Initialize cropPosition to center of screen
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        self._cropPosition = State(initialValue: CGPoint(x: screenWidth/2, y: screenHeight/2 - 50))
        self._lastPosition = State(initialValue: CGPoint(x: screenWidth/2, y: screenHeight/2 - 50))
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack {
                // Header
                Text("Move Circle to Crop")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                
                // Instruction text
                Text("Drag the circle to position • Pinch to zoom image")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)
                
                // Cropping area
                GeometryReader { geo in
                    ZStack {
                        // Image
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(scale)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastScale * value.magnitude
                                            scale = min(max(newScale, minScale), maxScale)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        }
                                )
                        }
                        
                        // Overlay - darker background with clear circle
                        GeometryReader { _ in
                            ZStack {
                                // Darkened background
                                Rectangle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                // Clear circle using blend mode
                                Circle()
                                    .frame(width: cropSize, height: cropSize)
                                    .position(cropPosition)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                            
                            // Visible circle border
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: cropSize, height: cropSize)
                                .position(cropPosition)
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            // Update crop position with constraints to keep within bounds
                                            let newPosition = CGPoint(
                                                x: lastPosition.x + gesture.translation.width,
                                                y: lastPosition.y + gesture.translation.height
                                            )
                                            
                                            // Ensure circle stays within view bounds
                                            let minX = cropSize/2
                                            let maxX = geo.size.width - cropSize/2
                                            let minY = cropSize/2
                                            let maxY = geo.size.height - cropSize/2
                                            
                                            cropPosition = CGPoint(
                                                x: min(maxX, max(minX, newPosition.x)),
                                                y: min(maxY, max(minY, newPosition.y))
                                            )
                                        }
                                        .onEnded { _ in
                                            lastPosition = cropPosition
                                        }
                                )
                            
                            // Add glowing effect to circle
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: cropSize, height: cropSize)
                                .position(cropPosition)
                        }
                    }
                }
                
                Spacer()
                
                // Buttons
                HStack(spacing: 40) {
                    // Cancel button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Crop button
                    Button(action: {
                        if let sourceImage = image {
                            let croppedImage = cropImage(sourceImage)
                            onCrop(croppedImage)
                            isPresented = false
                        }
                    }) {
                        Text("Crop")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 56/255, green: 189/255, blue: 248/255),
                                                Color(red: 29/255, green: 78/255, blue: 216/255)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func cropImage(_ sourceImage: UIImage) -> UIImage {
        // Get the view size where we're displaying the image
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height - 200 // Approximate height of the image area
        
        // Calculate the position of the crop circle relative to the image
        let viewCenterX = screenWidth / 2
        let viewCenterY = screenHeight / 2
        
        // Calculate the offset of the crop center from the view center
        let offsetX = cropPosition.x - viewCenterX
        let offsetY = cropPosition.y - viewCenterY
        
        // Calculate scaled image dimensions
        let imageAspect = sourceImage.size.width / sourceImage.size.height
        let screenAspect = screenWidth / screenHeight
        
        var scaledImageSize: CGSize
        if imageAspect > screenAspect {
            // Image is wider than screen
            scaledImageSize = CGSize(
                width: screenHeight * imageAspect,
                height: screenHeight
            )
        } else {
            // Image is taller than screen
            scaledImageSize = CGSize(
                width: screenWidth,
                height: screenWidth / imageAspect
            )
        }
        
        // Apply the user's scale
        let displayedImageWidth = scaledImageSize.width * scale
        let displayedImageHeight = scaledImageSize.height * scale
        
        // Calculate the crop rectangle in the scaled image coordinates
        let centerOffsetX = (displayedImageWidth - screenWidth) / 2
        let centerOffsetY = (displayedImageHeight - screenHeight) / 2
        
        // Create a context to draw the circular crop
        UIGraphicsBeginImageContextWithOptions(CGSize(width: cropSize, height: cropSize), false, 0)
        
        // Create circular clipping path
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: cropSize, height: cropSize))
        path.addClip()
        
        // Calculate where to draw the image so that the desired area appears in the crop circle
        let drawRectX = -centerOffsetX - offsetX
        let drawRectY = -centerOffsetY - offsetY
        
        sourceImage.draw(in: CGRect(
            x: drawRectX,
            y: drawRectY,
            width: displayedImageWidth,
            height: displayedImageHeight
        ))
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext() ?? sourceImage
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
}