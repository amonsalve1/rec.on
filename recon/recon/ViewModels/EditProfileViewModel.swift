//
//  EditProfileViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Combine
import PhotosUI
import SwiftUI

extension EditProfileView {

    /// The ViewModel for the edit-profile sheet.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var name: String
        @Published var location: String
        @Published var selectedPhoto: PhotosPickerItem?
        @Published var profileImage: UIImage?
        @Published var profilePicturePath: String
        @Published var isLoading = false
        @Published var errorMessage: String?

        // MARK: - Computed Properties

        var canSave: Bool {
            !name.isEmpty && !isLoading
        }

        // MARK: - Init

        init(name: String, location: String, picturePath: String) {
            self.name = name
            self.location = location
            self.profilePicturePath = picturePath
        }

        // MARK: - Helpers

        /// Loads the current profile picture into `profileImage`.
        func loadExistingImage() {
            guard !profilePicturePath.isEmpty else { return }

            profileImage = ProfileImageStore.load(from: profilePicturePath)
        }

        /// Reads the picked photo, shows it, and persists it to documents.
        func handlePhotoSelection(_ item: PhotosPickerItem?) async {
            guard
                let item,
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                return
            }

            profileImage = image
            if let fileName = ProfileImageStore.save(image) {
                profilePicturePath = fileName
            }
        }

        // MARK: - Requests

        /// Persists the edited fields. Returns once saving has finished so
        /// the view can notify its caller and dismiss.
        func save() async {
            errorMessage = nil
            isLoading = true

            UserDefaults.standard.set(name, forKey: "userName")
            if !location.isEmpty {
                UserDefaults.standard.set(location, forKey: "userLocation")
            } else {
                UserDefaults.standard.removeObject(forKey: "userLocation")
            }

            try? await Task.sleep(nanoseconds: 300_000_000)

            isLoading = false
        }

    }

}
