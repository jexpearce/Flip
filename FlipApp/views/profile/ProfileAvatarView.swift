import Foundation
import SwiftUI
import Kingfisher
import FirebaseStorage

struct ProfileAvatarView: View {
    let imageURL: String?
    let size: CGFloat
    let username: String
    
    init(imageURL: String?, size: CGFloat = 80, username: String = "") {
        self.imageURL = imageURL
        self.size = size
        self.username = username
    }
    
    var body: some View {
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
}

// Enhanced profile avatar with streak effects
struct EnhancedProfileAvatarWithStreak: View {
    let imageURL: String?
    let size: CGFloat
    let username: String
    let streakStatus: StreakStatus
    @State private var isAnimating = false
    @State private var pulseEffect = false
    
    init(imageURL: String?, size: CGFloat = 80, username: String = "", streakStatus: StreakStatus = .none) {
        self.imageURL = imageURL
        self.size = size
        self.username = username
        self.streakStatus = streakStatus
    }
    
    var body: some View {
        ZStack {
            // Base profile avatar
            ProfileAvatarView(
                imageURL: imageURL,
                size: size,
                username: username
            )
            
            // Enhanced streak effect if applicable
            if streakStatus != .none {
                // Outer glow effect
                Circle()
                    .stroke(
                        streakStatus == .redFlame ?
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.9),
                                    Color.red.opacity(0.7),
                                    Color.red.opacity(0.5),
                                    Color.red.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.9),
                                    Color.orange.opacity(0.7),
                                    Color.orange.opacity(0.5),
                                    Color.orange.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                        lineWidth: size * 0.1
                    )
                    .scaleEffect(isAnimating ? 1.1 : 0.95)
                    .animation(Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: isAnimating)
                
                // Second pulse ring for more dramatic effect
                Circle()
                    .stroke(
                        streakStatus == .redFlame ?
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.7),
                                    Color.orange.opacity(0.5),
                                    Color.yellow.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.7),
                                    Color.yellow.opacity(0.5),
                                    Color.orange.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                        lineWidth: size * 0.05
                    )
                    .scaleEffect(pulseEffect ? 1.15 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulseEffect)
                
                // Fire emblems around the circle (for raging fire effect)
                ForEach(0..<6) { index in
                    let angle = Double(index) * (360.0 / 6.0)
                    FireEmblems(
                        size: size * 0.2,
                        color: streakStatus == .redFlame ? .red : .orange,
                        angle: angle,
                        distance: size * 0.65,
                        delay: Double(index) * 0.1
                    )
                }
                
                // Main flame indicator badge
                ZStack {
                    Circle()
                        .fill(
                            streakStatus == .redFlame ?
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.red, Color.red.opacity(0.7)]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: size * 0.2
                                ) :
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: size * 0.2
                                )
                        )
                        .frame(width: size * 0.3, height: size * 0.3)
                        .shadow(
                            color: streakStatus == .redFlame ? Color.red.opacity(0.7) : Color.orange.opacity(0.7),
                            radius: 6
                        )
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: size * 0.18, weight: .bold))
                        .foregroundStyle(
                            streakStatus == .redFlame ?
                                LinearGradient(
                                    colors: [Color.white, Color.yellow.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    colors: [Color.white, Color.yellow.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 1)
                        .offset(y: isAnimating ? -1 : 1)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                }
                .position(x: size * 0.8, y: size * 0.15)
            }
        }
        .onAppear {
            if streakStatus != .none {
                withAnimation {
                    isAnimating = true
                    
                    // Slight delay for second animation to create more dynamic effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        pulseEffect = true
                    }
                }
            }
        }
    }
}

// Helper view for fire emblems around the streak circle
struct FireEmblems: View {
    let size: CGFloat
    let color: Color
    let angle: Double
    let distance: CGFloat
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        color,
                        color == .red ? Color.orange : Color.yellow
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: color.opacity(0.6), radius: 3)
            .scaleEffect(isAnimating ? 1.0 + Double.random(in: 0.1...0.25) : 0.8)
            .offset(
                x: cos(angle * .pi / 180) * distance,
                y: sin(angle * .pi / 180) * distance
            )
            .animation(
                Animation.easeInOut(duration: 0.8 + Double.random(in: 0...0.4))
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isAnimating = true
                }
            }
    }
}

// Helper for caching profile images and optimizing loading
// Update the existing ProfileImageCache class in ProfileAvatarView.swift
class ProfileImageCache {
    static let shared = ProfileImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    // Get image directly from cache (for map markers)
    func getCachedImage(for userId: String) -> UIImage? {
        return cache.object(forKey: NSString(string: userId))
    }
    
    // Store image directly in cache
    func storeImage(_ image: UIImage, for userId: String) {
        cache.setObject(image, forKey: NSString(string: userId))
    }
    
    // Clear cache for specific user
    func clearCacheForUser(_ userId: String) {
        cache.removeObject(forKey: NSString(string: userId))
    }
    
    // This method is for backward compatibility with your existing code
    func getImage(for urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Extract user ID from URL if it contains one, otherwise use the whole URL
        let userId = urlString.split(separator: "/").last?.split(separator: "_").first.map(String.init) ?? urlString
        
        // Check if image is already in memory cache
        let cacheKey = NSString(string: urlString)
        if let cachedImage = cache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        // If not in cache, download from Firebase
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Store in cache - both with URL and with userId if available
            self?.cache.setObject(image, forKey: cacheKey)
            self?.cache.setObject(image, forKey: NSString(string: userId))
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
