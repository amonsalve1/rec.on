//
//  ProfileViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Combine
import UIKit

extension ProfileView {

    /// The ViewModel for the profile page, for the signed-in user or a friend.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var profile: LocalProfile?
        @Published var recentPicks: [FinalPick] = []
        @Published var isLoading = false
        @Published var isLoadingProfile = false
        @Published var errorMessage: String?
        @Published var showEditSheet = false

        /// The profile being shown, or `nil` for the signed-in user's own.
        let userId: Int?

        // MARK: - Computed Properties

        var isOwnProfile: Bool {
            userId == nil
        }

        // MARK: - Init

        init(userId: Int?) {
            self.userId = userId
        }

        // MARK: - Requests

        /// Builds the displayed profile from the locally stored values.
        func loadProfile(name: String, location: String, picturePath: String) {
            guard !isLoadingProfile else { return }
            isLoadingProfile = true

            profile = LocalProfile(
                name: name,
                location: location,
                friendsCount: 0,
                profilePictureUrl: picturePath.isEmpty ? nil : picturePath
            )
            isLoadingProfile = false
        }

        /// Loads the persisted recent picks into `recentPicks`.
        func loadRecentPicks() {
            guard !isLoading else { return }
            isLoading = true
            errorMessage = nil

            recentPicks = RecentPicksStore.load()
            isLoading = false
        }

        // MARK: - Helpers

        /// Loads an image from the documents directory, or `nil` if the file
        /// is missing or unreadable.
        func loadImage(from path: String) -> UIImage? {
            ProfileImageStore.load(from: path)
        }

    }

}
