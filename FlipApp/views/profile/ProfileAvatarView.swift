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

// Helper for caching profile images and optimizing loading
class ProfileImageCache {
    static let shared = ProfileImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    func getImage(for urlString: String, completion: @escaping (UIImage?) -> Void) {
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
            
            // Store in cache
            self?.cache.setObject(image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}