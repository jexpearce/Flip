import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import SwiftUI

class ProfileImageManager: NSObject, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var profileImage: UIImage?
    @Published var isImagePickerPresented = false
    @Published var isCropperPresented = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var showUploadError = false
    @Published var errorMessage = ""

    var onImageUploaded: ((String) -> Void)?

    private let storage = Storage.storage().reference()
    private let db = Firestore.firestore()

    // Select image from photo library
    func selectImage() { isImagePickerPresented = true }

    // Upload the cropped image to Firebase Storage
    func uploadImage() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
            let imageData = profileImage?.jpegData(compressionQuality: 0.7)
        else {
            showError("Could not prepare image for upload")
            return
        }

        isUploading = true
        uploadProgress = 0.0

        // Create a reference to the file path in Firebase Storage
        let profileImagesRef = storage.child(
            "profile_images/\(currentUserId)_\(Date().timeIntervalSince1970).jpg"
        )

        // Upload the image
        let uploadTask = profileImagesRef.putData(imageData, metadata: nil) {
            [weak self] metadata, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isUploading = false

                if let error = error {
                    self.showError("Upload failed: \(error.localizedDescription)")
                    return
                }

                // Get the download URL
                profileImagesRef.downloadURL { [weak self] url, error in
                    guard let self = self else { return }

                    if let error = error {
                        self.showError("Couldn't get download URL: \(error.localizedDescription)")
                        return
                    }

                    guard let downloadURL = url else {
                        self.showError("Download URL is nil")
                        return
                    }

                    // Update the user's profile in Firestore
                    self.updateUserProfile(with: downloadURL.absoluteString)
                }
            }
        }

        // Track upload progress
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let self = self, let progress = snapshot.progress else { return }

            DispatchQueue.main.async {
                self.uploadProgress =
                    Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }

    // Update the user's profile in Firestore with the new image URL
    private func updateUserProfile(with imageURL: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            showError("User not logged in")
            return
        }

        db.collection("users").document(currentUserId)
            .updateData(["profileImageURL": imageURL]) { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    self.showError("Failed to update profile: \(error.localizedDescription)")
                    return
                }

                // Notify listeners that the image has been uploaded
                self.onImageUploaded?(imageURL)

                // Also update the FirebaseManager's currentUser
                if var currentUser = FirebaseManager.shared.currentUser {
                    currentUser.profileImageURL = imageURL
                    FirebaseManager.shared.currentUser = currentUser
                }
            }
    }

    // Load the current user's profile image
    func loadProfileImage() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId)
            .getDocument { [weak self] document, error in
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self),
                    let imageURL = userData.profileImageURL, !imageURL.isEmpty,
                    let url = URL(string: imageURL)
                {

                    URLSession.shared
                        .dataTask(with: url) { data, response, error in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async { self?.profileImage = image }
                            }
                        }
                        .resume()
                }
            }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showUploadError = true
            self.isUploading = false
        }
    }
}

// SwiftUI wrapper for PHPickerViewController
struct PHPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var onSelect: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerRepresentable

        init(_ parent: PHPickerRepresentable) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard let result = results.first else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                if let image = reading as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image
                        self?.parent.onSelect()
                    }
                }
            }
        }
    }
}
