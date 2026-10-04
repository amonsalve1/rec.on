//
//  ProfileSetupViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 10/2/2026.
//

import Combine
import Foundation

extension ProfileSetupView {

    /// The ViewModel for the post-sign-up profile step: the form state and
    /// the save, so the view only lays them out.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var name: String = ""
        @Published var location: String = ""
        @Published var isLoading = false
        @Published var errorMessage: String?

        private let defaults: UserDefaults

        // MARK: - Init

        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
        }

        // MARK: - Functions

        /// Stores the profile locally and releases the flow into the app.
        func saveProfile() async {
            guard !name.isEmpty else { return }

            errorMessage = nil
            isLoading = true

            defaults.set(name, forKey: Keys.userName)

            if location.isEmpty {
                defaults.removeObject(forKey: Keys.userLocation)
            } else {
                defaults.set(location, forKey: Keys.userLocation)
            }

            /// A beat so the control's loading state is seen rather than
            /// flashed; the write itself is synchronous.
            try? await Task.sleep(nanoseconds: 300_000_000)

            isLoading = false
            defaults.set(false, forKey: Keys.needsProfileSetup)
        }

        // MARK: - Keys

        private enum Keys {
            static let userName = "userName"
            static let userLocation = "userLocation"
            static let needsProfileSetup = "needsProfileSetup"
        }

    }

}
