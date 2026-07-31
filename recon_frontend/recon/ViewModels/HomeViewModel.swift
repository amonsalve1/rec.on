//
//  HomeViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Combine
import CoreLocation
import Foundation

extension HomeView {

    /// One thing a member can decide on, offered straight from the home
    /// screen so starting a session takes a single tap.
    struct Topic: Identifiable {
        let id: String
        let title: String
        let systemImage: String

        /// Bundled artwork for the home card. All three are CC0 photographs
        /// from Wikimedia Commons; see docs/credits.md.
        let imageName: String
    }

    /// The ViewModel for the Home page view.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var showMenu = false
        @Published var showProfile = false
        @Published var showProfileFromPicks = false
        @Published var showEditProfile = false
        @Published var recentPicks: [FinalPick] = []
        @Published private(set) var liveParties: [PartySummaryDTO] = []

        /// A real nearby place for the food card, once location is known.
        @Published private(set) var nearbyPreview: PlacePreviewDTO?
        @Published private(set) var nearbyCount: Int = 0

        /// The topic the user tapped, awaiting a solo-or-party choice.
        @Published var pendingTopic: Topic?

        let topics: [Topic] = [
            Topic(
                id: "food",
                title: "Food nearby",
                systemImage: "fork.knife",
                imageName: "TopicFood"
            ),
            Topic(
                id: "study",
                title: "Study spots",
                systemImage: "books.vertical",
                imageName: "TopicStudy"
            ),
            Topic(
                id: "movie",
                title: "Movies",
                systemImage: "film",
                imageName: "TopicMovie"
            )
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

            NotificationCenter.default
                .publisher(for: .sessionFinished)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.refresh()
                }
                .store(in: &bag)
        }

        // MARK: - Requests

        /// Reloads everything the home screen shows.
        func refresh() {
            loadRecentPicks()
            loadLiveParties()
            loadNearbyPreview()
        }

        /// Asks the server what is nearby, but only when location has already
        /// been granted elsewhere in the app. Home must never be the screen
        /// that triggers the permission prompt.
        func loadNearbyPreview() {
            let status = LocationService.shared.authorizationStatus
            guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }

            LocationService.shared.getCurrentLocation { [weak self] result in
                guard let location = try? result.get() else { return }

                RecOnAPI.shared.previewNearby(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                ) { preview in
                    DispatchQueue.main.async {
                        if case .success(let envelope) = preview {
                            self?.nearbyPreview = envelope.place
                            self?.nearbyCount = envelope.count
                        }
                    }
                }
            }
        }

        /// Fetches the parties this user is still part of.
        func loadLiveParties() {
            RecOnAPI.shared.listParties { result in
                DispatchQueue.main.async {
                    if case .success(let parties) = result {
                        self.liveParties = parties
                    }
                }
            }
        }

        /// Loads the persisted recent picks into `recentPicks`.
        func loadRecentPicks() {
            recentPicks = RecentPicksStore.load()
        }

        // MARK: - Helpers

        /// A short line describing what a party is waiting on, written from
        /// this member's point of view.
        func statusLine(for party: PartySummaryDTO) -> String {
            if party.state == "lobby" {
                return party.memberCount > 1
                    ? "\(party.memberCount) in the lobby"
                    : "Waiting for friends to join"
            }

            if party.viewer.swipedCount < party.optionCount {
                let left = party.optionCount - party.viewer.swipedCount
                return "\(left) card\(left == 1 ? "" : "s") left to swipe"
            }

            if !party.viewer.hasPicked {
                return "Time to pick your favorite"
            }

            let waiting = party.memberCount - party.submittedCount
            return waiting > 0
                ? "Waiting on \(waiting) other\(waiting == 1 ? "" : "s")"
                : "Everyone has picked"
        }

        /// True when the party is blocked on this member rather than others.
        func isYourTurn(_ party: PartySummaryDTO) -> Bool {
            guard party.state == "swiping" else { return false }
            return party.viewer.swipedCount < party.optionCount || !party.viewer.hasPicked
        }

    }

}
