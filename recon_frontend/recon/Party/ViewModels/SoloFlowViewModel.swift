//
//  SoloFlowViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import Combine
import Foundation

extension SoloFlowView {

    /// The ViewModel for the solo flow: local-only swiping with no session.
    final class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var candidates: [PartyCandidate] = []
        @Published var liked: [PartyCandidate] = []
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?

        var imageMap: [String: String] = [:]
        var addressMap: [String: String] = [:]
        var tagsMap: [String: [String]] = [:]

        // MARK: - Requests

        /// Generates options for the topic and builds the local candidates.
        func startSolo(topic: String, completion: @escaping (Bool) -> Void) {
            isLoading = true
            errorMessage = nil
            liked = []
            candidates = []

            let backendTopic = mapTopicToBackend(topic)

            PartyOptionsGenerator.generateOptions(for: topic) { options, imageMap, addressMap, tagsMap in
                self.imageMap = imageMap
                self.addressMap = addressMap
                self.tagsMap = tagsMap
                self.createCandidates(topic: backendTopic, options: options, completion: completion)
            }
        }

        // MARK: - Helpers

        /// Maps a user-facing topic to the backend's topic identifier.
        func mapTopicToBackend(_ topic: String) -> String {
            let lower = topic.lowercased()
            if lower == "food" { return "restaurant" }
            if lower == "study" { return "activity" }
            if lower == "movie" || lower == "movies" { return "movie" }
            return lower
        }

        /// Builds the swipeable candidates from the generated options.
        func createCandidates(topic: String, options: [String], completion: @escaping (Bool) -> Void) {
            Task { @MainActor in
                self.candidates = options.map { optionName in
                    let imageUrl = self.imageMap[optionName]
                    let address = self.addressMap[optionName]
                        ?? self.generateAddress(for: optionName, topic: topic)
                    let tags = self.tagsMap[optionName]
                        ?? self.generateTags(for: optionName, topic: topic)
                    return PartyCandidate(
                        name: optionName,
                        address: address,
                        tags: tags,
                        imageName: "food1",
                        imageUrl: imageUrl
                    )
                }
                self.isLoading = false
                completion(true)
            }
        }

        /// Placeholder address used when the provider gave none.
        func generateAddress(for name: String, topic: String) -> String {
            if topic == "restaurant" {
                return "123 Main St, City, State"
            }
            if topic == "movie" {
                return "Available on streaming"
            }
            return "Nearby location"
        }

        /// Placeholder tags used when the provider gave none.
        func generateTags(for name: String, topic: String) -> [String] {
            if topic == "restaurant" { return ["Casual", "Dining"] }
            if topic == "movie" { return ["Action", "Thriller"] }
            if topic == "activity" { return ["Quiet", "Study"] }
            return ["Popular"]
        }

        /// Tracks a local like; solo mode records nothing remotely.
        func recordSwipe(for candidate: PartyCandidate, liked: Bool) {
            if liked {
                self.liked.append(candidate)
            }
        }

    }

}
