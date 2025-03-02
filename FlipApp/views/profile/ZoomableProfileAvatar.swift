import Foundation
import SwiftUI
import Kingfisher

struct ZoomableProfileAvatar: View {
    let imageURL: String?
    let size: CGFloat
    let username: String
    
    @State private var showEnlarged = false
    @State private var dragAmount = CGSize.zero
    @State private var scale: CGFloat = 1.0
    
    init(imageURL: String?, size: CGFloat = 80, username: String = "") {
        self.imageURL = imageURL
        self.size = size
        self.username = username
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                showEnlarged = true
            }
        }) {
            // Regular profile avatar
            if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        placeholderView
                    }
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2)))
                    .scaleFactor(UIScreen.main.scale)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
            } else {
                placeholderView
            }
        }
        .buttonStyle(ScaledButtonStyle())
        .fullScreenCover(isPresented: $showEnlarged) {
            // Full screen enlarged view
            ZStack {
                // Dark background
                Color.black.opacity(0.9)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showEnlarged = false
                        }
                    }
                
                // Enlarged image with gestures
                if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            largePlaceholderView
                        }
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(scale)
                        .offset(dragAmount)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragAmount = value.translation
                                }
                                .onEnded { value in
                                    // Optional: Spring back to center if desired
                                    withAnimation(.spring()) {
                                        if scale <= 1.0 {
                                            dragAmount = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, min(4.0, value))
                                }
                                .onEnded { value in
                                    // Reset zoom if pinched smaller than original
                                    withAnimation(.spring()) {
                                        if scale < 1.0 {
                                            scale = 1.0
                                            dragAmount = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation(.spring()) {
                                        if scale > 1.0 {
                                            scale = 1.0
                                            dragAmount = .zero
                                        } else {
                                            scale = 2.0
                                        }
                                    }
                                }
                        )
                } else {
                    largePlaceholderView
                }
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showEnlarged = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(20)
                        }
                    }
                    
                    Spacer()
                }
            }
            .statusBar(hidden: true)
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Theme.buttonGradient)
                .frame(width: size, height: size)
                .opacity(0.2)
            
            if !username.isEmpty && username.count >= 1 {
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.8))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: size * 0.075)
    }
    
    private var largePlaceholderView: some View {
        let largeSize: CGFloat = 200
        
        return ZStack {
            Circle()
                .fill(Theme.buttonGradient)
                .frame(width: largeSize, height: largeSize)
                .opacity(0.2)
            
            if !username.isEmpty && username.count >= 1 {
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: largeSize * 0.4, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: largeSize * 0.8))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 15)
    }
}

struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}