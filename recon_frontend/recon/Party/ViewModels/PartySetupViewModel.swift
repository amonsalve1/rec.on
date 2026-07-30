//
//  PartySetupViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import Combine
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

        private(set) var session: SessionDTO?
        var candidateIdToOptionId = [UUID: Int]()
        var imageMap = [String: String]()
        var addressMap = [String: String]()
        var tagsMap = [String: [String]]()

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
            guard
                let session = session,
                let participants = session.participants
            else {
                return false
            }
            return allFinalPicks.count >= participants.count
        }

        var poolOfPicks: [PartyCandidate] {
            allFinalPicks.map(PartyCandidate.init)
        }

        var backendWinner: PartyCandidate? {
            guard let winner = session?.winner else { return nil }

            let imageUrl = winner.option_details?["image_url"]
            let address = winner.option_details?["address"] ?? "Address not available"

            let tags: [String] = {
                if let tagString = winner.option_details?["tags"],
                   let data = tagString.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode([String].self, from: data) {
                    return decoded
                }
                return []
            }()

            return PartyCandidate(
                backendId: Int(winner.option_id ?? ""),
                name: winner.option_name ?? "Unknown",
                address: address,
                tags: tags,
                imageName: "food1",
                imageUrl: imageUrl
            )
        }

        var inviteLinkString: String? {
            guard let sessionId = session?.id else { return nil }
            return api.baseURL.appendingPathComponent("\(sessionId)/join/").absoluteString
        }

        // MARK: - Requests

        /// Generates options for the topic, creates the backend session, and
        /// loads its options.
        func startParty(topic: String, completion: @escaping (Bool) -> Void) {
            isLoading = true
            errorMessage = nil
            liked.removeAll()
            candidates.removeAll()
            candidateIdToOptionId.removeAll()

            let backendTopic = topicMapping[topic.lowercased()] ?? topic.lowercased()

            PartyOptionsGenerator.generateOptions(for: topic) { options, imageMap, addressMap, tagsMap in
                self.imageMap = imageMap
                self.addressMap = addressMap
                self.tagsMap = tagsMap
                self.createSession(topic: backendTopic, options: options, completion: completion)
            }
        }

        /// Creates the backend session and loads its options.
        func createSession(topic: String, options: [String], completion: @escaping (Bool) -> Void) {
            api.createSession(topic: topic, options: options) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let session):
                        self.session = session
                        self.participants = session.participants ?? []
                        self.loadOptions(completion: completion)
                    case .failure:
                        self.isLoading = false
                        self.errorMessage = "Failed to create session"
                        completion(false)
                    }
                }
            }
        }

        /// Fetches the session's options into `candidates`.
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
                        self.candidates = options.map { opt in
                            self.mapToCandidate(from: opt)
                        }
                        completion(true)
                    case .failure:
                        self.errorMessage = "Failed to load options"
                        completion(false)
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

            api.recordSwipe(
                sessionId: sessionId,
                optionId: optionId,
                optionName: candidate.name,
                liked: liked,
                completion: nil
            )

            if liked {
                self.liked.append(candidate)
            }
        }

        /// Fetches the caller's liked options for the final-pick screen.
        func loadLikedOptions(completion: @escaping (Bool) -> Void) {
            guard let sessionId = session?.id else {
                completion(false)
                return
            }

            api.getLikedOptions(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let options):
                        self.likedOptions = options.map { self.mapToCandidate(from: $0) }
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

            let details = candidateDetails(from: candidate)

            api.submitFinalPick(
                sessionId: sessionId,
                optionId: optionId,
                optionName: candidate.name,
                optionDetails: details
            ) { result in
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

        /// Asks the backend to pick the session winner.
        func spinWheel(completion: @escaping (Result<[String: Any], Error>) -> Void) {
            guard let sessionId = session?.id else {
                let error = NSError(
                    domain: "PartyViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No session"]
                )
                completion(.failure(error))
                return
            }
            api.spinWheel(sessionId: sessionId, completion: completion)
        }

        /// Refreshes the participant list.
        func refreshParticipants() {
            guard let sessionId = session?.id else { return }

            api.getSession(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    if case .success(let session) = result {
                        self.participants = session.participants ?? []
                    }
                }
            }
        }

        /// Refreshes the whole session, including the winner if chosen.
        func refreshSession() {
            guard let sessionId = session?.id else { return }

            api.getSession(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    if case .success(let session) = result {
                        self.session = session
                        self.participants = session.participants ?? []
                    }
                }
            }
        }

        /// Joins an existing session by id and loads its options.
        func joinSession(sessionId: Int, completion: @escaping (Bool) -> Void) {
            isLoading = true
            errorMessage = nil

            api.joinSession(sessionId: sessionId) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let session):
                        self.session = session
                        self.participants = session.participants ?? []
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
        func mapToCandidate(from opt: BackendOption) -> PartyCandidate {
            let name = opt.text
            let imageUrl = imageMap[name]
            let address = addressMap[name] ?? "Address unknown"
            let tags = tagsMap[name] ?? []

            let candidate = PartyCandidate(
                name: name,
                address: address,
                tags: tags,
                imageName: "food1",
                imageUrl: imageUrl
            )
            candidateIdToOptionId[candidate.id] = opt.id
            return candidate
        }

        /// Serializes a candidate's display details for the pick payload, or
        /// `nil` if there is nothing to send.
        func candidateDetails(from candidate: PartyCandidate) -> [String: String]? {
            var details = [String: String]()

            if let url = candidate.imageUrl {
                details["image_url"] = url
            }
            if !candidate.address.isEmpty {
                details["address"] = candidate.address
            }
            if !candidate.tags.isEmpty,
               let data = try? JSONEncoder().encode(candidate.tags),
               let json = String(data: data, encoding: .utf8) {
                details["tags"] = json
            }

            return details.isEmpty ? nil : details
        }

    }

}
