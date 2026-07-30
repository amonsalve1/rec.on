//
//  PartySetupViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import Combine
import CoreLocation
import Foundation

extension PartySetupView {

    /// The ViewModel for the party flow, shared by the setup pages and the
    /// swipe, waiting, spin, and final-pick screens it presents.
    final class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published private(set) var candidates: [PartyCandidate] = []
        @Published private(set) var liked: [PartyCandidate] = []
        @Published private(set) var isLoading: Bool = false
        @Published private(set) var errorMessage: String?
        @Published private(set) var participants: [ParticipantDTO] = []
        @Published private(set) var likedOptions: [PartyCandidate] = []
        @Published private(set) var hasSubmittedFinalPick: Bool = false
        @Published private(set) var allFinalPicks: [FinalPickDTO] = []
        @Published private(set) var progress: [ProgressDTO] = []
        @Published private(set) var inviteCode: String?

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

        // MARK: - Computed Properties

        var allParticipantsHavePicked: Bool {
            guard let session = session else { return false }
            return allFinalPicks.count >= session.members.count
        }

        var poolOfPicks: [PartyCandidate] {
            allFinalPicks.map(PartyCandidate.init)
        }

        var backendWinner: PartyCandidate? {
            guard let winner = session?.winner else { return nil }
            return PartyCandidate(from: winner)
        }

        // MARK: - Requests

        /// Creates the party for the topic — the backend builds the option
        /// deck, using our location when the topic wants nearby places.
        func startParty(topic: String, completion: @escaping (Bool) -> Void) {
            isLoading = true
            errorMessage = nil
            liked.removeAll()
            candidates.removeAll()
            candidateIdToOptionId.removeAll()
            inviteCode = nil

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
                        self?.createParty(title: title, topic: backendTopic, location: location, completion: completion)
                    }
                }
            } else {
                createParty(title: title, topic: backendTopic, location: nil, completion: completion)
            }
        }

        /// Creates the backend party and loads its server-built options.
        func createParty(
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
                        self.participants = session.members
                        self.loadOptions(completion: completion)
                    case .failure:
                        self.isLoading = false
                        self.errorMessage = "Failed to create session"
                        completion(false)
                    }
                }
            }
        }

        /// Fetches the party's options into `candidates`.
        func loadOptions(completion: @escaping (Bool) -> Void) {
            guard let sessionId = session?.id else {
                errorMessage = "Missing session id."
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
                            self.mapToCandidate(from: option)
                        }
                        completion(true)
                    case .failure:
                        self.errorMessage = "Failed to load options"
                        completion(false)
                    }
                }
            }
        }

        /// Host: mints (or reuses) the invite code to share. Silently a no-op
        /// for guests, who cannot mint.
        func ensureInviteCode() {
            guard inviteCode == nil, let sessionId = session?.id else { return }

            api.mintInvite(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    if case .success(let code) = result {
                        self.inviteCode = code
                    }
                }
            }
        }

        /// Moves the party into swiping. The host starts it; a guest just
        /// verifies the host already has.
        func beginSwiping(completion: @escaping (Bool) -> Void) {
            guard let sessionId = session?.id else {
                completion(false)
                return
            }

            if session?.state == "swiping" {
                completion(true)
                return
            }

            api.startParty(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let session):
                        self.session = session
                        completion(true)
                    case .failure:
                        // not the host, or already started: trust a refresh
                        self.api.getSession(sessionId: sessionId) { refreshed in
                            DispatchQueue.main.async {
                                if case .success(let session) = refreshed, session.state == "swiping" {
                                    self.session = session
                                    completion(true)
                                } else {
                                    self.errorMessage = "Waiting for the host to start the party"
                                    completion(false)
                                }
                            }
                        }
                    }
                }
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

        /// Rebuilds the liked list for the final-pick screen from the
        /// backend's record of our swipes.
        func loadLikedOptions(completion: @escaping (Bool) -> Void) {
            guard let sessionId = session?.id else {
                completion(false)
                return
            }

            api.getMySwipes(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let swipes):
                        let likedIds = Set(swipes.filter(\.liked).map(\.option_id))
                        self.likedOptions = self.candidates.filter { candidate in
                            guard let optionId = self.candidateIdToOptionId[candidate.id] else { return false }
                            return likedIds.contains(optionId)
                        }
                        completion(true)
                    case .failure:
                        self.errorMessage = "Failed to load liked options"
                        completion(false)
                    }
                }
            }
        }

        /// Submits the caller's final pick for the session.
        func submitFinalPick(candidate: PartyCandidate, completion: @escaping (Bool) -> Void) {
            guard
                let sessionId = session?.id,
                let optionId = candidateIdToOptionId[candidate.id]
            else {
                completion(false)
                return
            }

            api.submitFinalPick(sessionId: sessionId, optionId: optionId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.hasSubmittedFinalPick = true
                        completion(true)
                    case .failure:
                        self.errorMessage = "Failed to submit pick"
                        completion(false)
                    }
                }
            }
        }

        /// Refreshes each participant's swipe progress.
        func refreshProgress(completion: @escaping () -> Void) {
            guard let sessionId = session?.id else {
                completion()
                return
            }

            api.getProgress(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    if case .success(let progress) = result {
                        self.progress = progress
                    }
                    completion()
                }
            }
        }

        /// Refreshes the set of submitted final picks.
        func refreshFinalPicks(completion: @escaping () -> Void) {
            guard let sessionId = session?.id else {
                completion()
                return
            }

            api.getAllFinalPicks(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    if case .success(let picks) = result {
                        self.allFinalPicks = picks
                    }
                    completion()
                }
            }
        }

        /// Asks the backend to draw the winner; the completed party (winner
        /// included) replaces the session.
        func spinWheel(completion: @escaping (Bool) -> Void) {
            guard let sessionId = session?.id else {
                completion(false)
                return
            }

            api.spinWheel(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let session):
                        self.session = session
                        self.participants = session.members
                        completion(true)
                    case .failure:
                        self.errorMessage = "Failed to spin the wheel"
                        completion(false)
                    }
                }
            }
        }

        /// Refreshes the participant list.
        func refreshParticipants() {
            guard let sessionId = session?.id else { return }

            api.getSession(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    if case .success(let session) = result {
                        self.session = session
                        self.participants = session.members
                    }
                }
            }
        }

        /// Refreshes the whole session, including the winner once chosen.
        func refreshSession() {
            refreshParticipants()
        }

        /// Joins an existing party by invite code and loads its options.
        func joinParty(code: String, completion: @escaping (Bool) -> Void) {
            isLoading = true
            errorMessage = nil

            api.joinParty(code: code) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let session):
                        self.session = session
                        self.participants = session.members
                        self.loadOptions(completion: completion)
                    case .failure:
                        self.errorMessage = "Failed to join session"
                        completion(false)
                    }
                }
            }
        }

        // MARK: - Helpers

        /// Builds a display candidate from a backend option, remembering the
        /// backend id for later swipes and picks.
        func mapToCandidate(from option: OptionDTO) -> PartyCandidate {
            let candidate = PartyCandidate(from: option)
            candidateIdToOptionId[candidate.id] = option.id
            return candidate
        }

    }

}
