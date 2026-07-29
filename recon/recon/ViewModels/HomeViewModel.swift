//
//  HomeViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Combine
import Foundation

extension HomeView {

    /// The ViewModel for the Home page view.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var showMenu = false
        @Published var showProfile = false
        @Published var showProfileFromPicks = false
        @Published var showEditProfile = false
        @Published var recentPicks: [FinalPick] = []

        /// Placeholder friend list shown until the backend provides one.
        let friends: [Friend] = [
            .init(name: "Mei Mei", imageName: "friend1"),
            .init(name: "Larry", imageName: "friend2"),
            .init(name: "Milly", imageName: "friend3"),
            .init(name: "Uni", imageName: "friend4")
        ]

        private var bag = Set<AnyCancellable>()

        // MARK: - Init

        init() {
            NotificationCenter.default
                .publisher(for: NSNotification.Name("RecentPicksUpdated"))
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.loadRecentPicks()
                }
                .store(in: &bag)
        }

        // MARK: - Helpers

        /// Loads the persisted recent picks from UserDefaults into `recentPicks`.
        func loadRecentPicks() {
            guard
                let data = UserDefaults.standard.data(forKey: "recentPicks"),
                let decoded = try? JSONDecoder().decode([RecentPickData].self, from: data)
            else {
                recentPicks = []
                return
            }

            recentPicks = decoded.map { pickData in
                FinalPick(
                    id: pickData.id,
                    name: pickData.name,
                    imageUrl: pickData.imageUrl,
                    address: pickData.address,
                    tags: pickData.tags,
                    timeAgo: pickData.timeAgo
                )
            }
        }

    }

}
