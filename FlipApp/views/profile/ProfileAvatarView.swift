import Kingfisher
import SwiftUI

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
            KFImage(url).placeholder { placeholderView }.cacheMemoryOnly().fade(duration: 0.25)
                .setProcessor(
                    DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2))
                )
                .scaleFactor(UIScreen.main.scale).resizable().aspectRatio(contentMode: .fill)
                .frame(width: size, height: size).clipShape(Circle())
                .overlay(Circle().stroke(Theme.silveryGradient2, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.3), radius: 4)
        }
        else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Circle().fill(Theme.buttonGradient).frame(width: size, height: size).opacity(0.2)

            if !username.isEmpty && username.count >= 1 {
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold)).foregroundColor(.white)
            }
            else {
                Image(systemName: "person.circle.fill").font(.system(size: size * 0.8))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: size * 0.075)
    }
}

// Enhanced profile avatar with streak effects
struct EnhancedProfileAvatarWithStreak: View {
    let imageURL: String?
    let size: CGFloat
    let username: String
    let streakStatus: StreakStatus
    @State private var isGlowing = false

    init(
        imageURL: String?,
        size: CGFloat = 40,
        username: String = "",
        streakStatus: StreakStatus = .none
    ) {
        self.imageURL = imageURL
        self.size = size
        self.username = username
        self.streakStatus = streakStatus
    }

    var body: some View {
        ZStack {
            // Only show streak background if there's an active streak
            if streakStatus != .none {
                // UPDATED: Single large fire icon behind profile pic
                // No outer ring, just the fire effect
                ZStack {
                    // Large background fire effect
                    Circle()
                        .fill(
                            streakStatus == .redFlame
                                ? RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(0.7), Color.red.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: size * 0.8
                                )
                                : RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(0.7), Color.orange.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: size * 0.8
                                )
                        )
                        .frame(width: size * 1.2, height: size * 1.2)
                        .scaleEffect(isGlowing ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isGlowing
                        )

                    // Single flame icon that appears to be behind the profile pic
                    Image(systemName: "flame.fill").font(.system(size: size * 0.8))
                        .foregroundColor(
                            streakStatus == .redFlame ? .red.opacity(0.7) : .orange.opacity(0.7)
                        )
                        .shadow(
                            color: streakStatus == .redFlame
                                ? Color.red.opacity(0.7) : Color.orange.opacity(0.7),
                            radius: 8
                        )
                        .offset(y: size * 0.05)  // Slight offset to position flame
                        .scaleEffect(isGlowing ? 1.05 : 0.95)
                        .animation(
                            Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: isGlowing
                        )
                }
            }

            // Profile image remains on top of the flame
            if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                KFImage(url).placeholder { placeholderView }.cacheMemoryOnly().fade(duration: 0.25)
                    .setProcessor(
                        DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2))
                    )
                    .scaleFactor(UIScreen.main.scale).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size).clipShape(Circle())
                    .overlay(Circle().stroke(Theme.silveryGradient2, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
            }
            else {
                placeholderView
            }

            // Small indicator badge showing streak status if active
            if streakStatus != .none {
                ZStack {
                    Circle().fill(streakStatus == .redFlame ? Color.red : Color.orange)
                        .frame(width: size * 0.25, height: size * 0.25)

                    Image(systemName: "flame.fill").font(.system(size: size * 0.15))
                        .foregroundColor(.white)
                }
                .shadow(
                    color: streakStatus == .redFlame
                        ? Color.red.opacity(0.7) : Color.orange.opacity(0.7),
                    radius: 4
                )
                .position(x: size * 0.8, y: size * 0.2)  // Position in top-right corner
            }
        }
        .onAppear { if streakStatus != .none { isGlowing = true } }
    }

    private var placeholderView: some View {
        ZStack {
            Circle().fill(Theme.buttonGradient).frame(width: size, height: size).opacity(0.2)

            if !username.isEmpty && username.count >= 1 {
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold)).foregroundColor(.white)
            }
            else {
                Image(systemName: "person.circle.fill").font(.system(size: size * 0.8))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: size * 0.075)
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

    func clearCache() { cache.removeAllObjects() }
}
