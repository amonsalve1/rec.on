//
//  SoloFlowViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import Combine
import CoreLocation
import Foundation

extension SoloFlowView {

    /// The ViewModel for the solo flow: a party of one riding the same v1
    /// backend as group mode — the server builds the deck, records swipes,
    /// and draws the winner from the likes.
    final class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published private(set) var candidates: [PartyCandidate] = []
        @Published private(set) var liked: [PartyCandidate] = []
        @Published private(set) var isLoading: Bool = false
        @Published private(set) var errorMessage: String?

        private(set) var session: SessionDTO?
        var candidateIdToOptionId = [UUID: Int]()

        let api = RecOnAPI.shared

        /// Maps user-facing topics to the backend's topic identifiers.
        let topicMapping: [String: String] = [
            "food": "restaurant",
            "study": "activity",
            "movie": "movie",
            "movies": "movie"
        ]

        // MARK: - Requests

        /// Creates a single-member party for the topic, starts it, and loads
        /// the server-built deck.
        func startSolo(topic: String, completion: @escaping (Bool) -> Void) {
            isLoading = true
            errorMessage = nil
            liked = []
            candidates = []
            candidateIdToOptionId.removeAll()

            let backendTopic = topicMapping[topic.lowercased()] ?? topic.lowercased()
            let title = topic.capitalized

            if backendTopic == "restaurant" {
                Task { @MainActor in
                    LocationService.shared.getCurrentLocation { [weak self] result in
                        let location = (try? result.get()).map {
                            CreatePartyRequest.Location(
                                lat: $0.coordinate.latitude,
                                lon: $0.coordinate.longitude
                            )
                        }
                        self?.createAndStart(title: title, topic: backendTopic, location: location, completion: completion)
                    }
                }
            } else {
                createAndStart(title: title, topic: backendTopic, location: nil, completion: completion)
            }
        }

        /// Records a swipe on the backend and tracks local likes.
        func recordSwipe(for candidate: PartyCandidate, liked: Bool) {
            guard
                let sessionId = session?.id,
                let optionId = candidateIdToOptionId[candidate.id]
            else {
                return
            }

            api.recordSwipe(sessionId: sessionId, optionId: optionId, liked: liked, completion: nil)

            if liked {
                self.liked.append(candidate)
            }
        }

        /// Asks the backend to draw the winner from the likes. A party of one
        /// needs no final pick — every liked option is a tied approval leader,
        /// so the spin is a uniform draw over them, server-side.
        func spin(completion: @escaping (PartyCandidate?) -> Void) {
            guard let sessionId = session?.id else {
                completion(nil)
                return
            }

            api.spinWheel(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let session):
                        self.session = session
                        completion(session.winner.map(PartyCandidate.init))
                    case .failure:
                        self.errorMessage = "Failed to pick a winner"
                        completion(nil)
                    }
                }
            }
        }

        // MARK: - Helpers

        /// Create the backend party, start it (we are the host), then load
        /// its options into `candidates`.
        private func createAndStart(
            title: String,
            topic: String,
            location: CreatePartyRequest.Location?,
            completion: @escaping (Bool) -> Void
        ) {
            api.createParty(title: title, topic: topic, location: location) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let session):
                        self.session = session
                        self.api.startParty(sessionId: session.id) { started in
                            DispatchQueue.main.async {
                                switch started {
                                case .success(let session):
                                    self.session = session
                                    self.loadOptions(completion: completion)
                                case .failure:
                                    self.isLoading = false
                                    self.errorMessage = "Failed to start session"
                                    completion(false)
                                }
                            }
                        }
                    case .failure:
                        self.isLoading = false
                        self.errorMessage = "Failed to create session"
                        completion(false)
                    }
                }
            }
        }

        private func loadOptions(completion: @escaping (Bool) -> Void) {
            guard let sessionId = session?.id else {
                isLoading = false
                completion(false)
                return
            }

            api.getOptions(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let options):
                        self.candidates = options.map { option in
                            let candidate = PartyCandidate(from: option)
                            self.candidateIdToOptionId[candidate.id] = option.id
                            return candidate
                        }
                        completion(true)
                    case .failure:
                        self.errorMessage = "Failed to load options"
                        completion(false)
                    }
                }
            }
        }

    }

}
