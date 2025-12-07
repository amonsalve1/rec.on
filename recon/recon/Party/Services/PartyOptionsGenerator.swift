//
//  PartyOptionsGenerator.swift
//  recon
//
//  Created by Ethan Chen on 12/4/2024.
//

import Foundation
import CoreLocation

struct PartyOptionsGenerator {
    static func generateOptions(for topic: String, completion: @escaping ([String], [String: String], [String: String], [String: [String]]) -> Void) {
        let backendTopic = mapTopicToBackend(topic)
        
        if backendTopic == "restaurant" {
            generateRestaurantOptions(completion: completion)
        } else {
            let options = generateDefaultOptions(for: topic)
            var imageMap: [String: String] = [:]
            
            for option in options {
                if backendTopic == "movie" {
                    imageMap[option] = getMovieImageUrl(for: option)
                } else if backendTopic == "activity" {
                    imageMap[option] = getStudySpotImageUrl(for: option)
                }
            }
            
            completion(options, imageMap, [:], [:])
        }
    }
    
    private static func generateRestaurantOptions(completion: @escaping ([String], [String: String], [String: String], [String: [String]]) -> Void) {
        Task { @MainActor in
            LocationService.shared.getCurrentLocation { result in
                switch result {
                case .success(let location):
                    RestaurantAPI.shared.searchNearbyRestaurants(location: location) { restaurantResult in
                        switch restaurantResult {
                        case .success(let infos):
                            if !infos.isEmpty {
                                var imageMap: [String: String] = [:]
                                var addressMap: [String: String] = [:]
                                var tagsMap: [String: [String]] = [:]
                                
                                for info in infos {
                                    let imageUrl = info.imageUrl ?? RestaurantAPI.shared.getRestaurantImageUrl(for: info.name)
                                    imageMap[info.name] = imageUrl
                                    addressMap[info.name] = info.address
                                    tagsMap[info.name] = info.tags
                                }
                                
                            completion(infos.map { $0.name }, imageMap, addressMap, tagsMap)
                        } else {
                                completion(generateDefaultOptions(for: "food"), [:], [:], [:])
                            }
                        case .failure:
                            completion(generateDefaultOptions(for: "food"), [:], [:], [:])
                        }
                    }
                case .failure:
                    completion(generateDefaultOptions(for: "food"), [:], [:], [:])
                }
            }
        }
    }
    
    private static func mapTopicToBackend(_ topic: String) -> String {
        let lower = topic.lowercased()
        if lower == "food" { return "restaurant" }
        if lower == "study" { return "activity" }
        if lower == "movie" || lower == "movies" { return "movie" }
        return lower
    }
    
    static func generateDefaultOptions(for topic: String) -> [String] {
        let lower = topic.lowercased()
        if lower == "movie" || lower == "movies" {
            return ["The Matrix", "Inception", "The Dark Knight", "Pulp Fiction", "Interstellar", "The Shawshank Redemption", "Fight Club", "Goodfellas"]
        }
        if lower == "food" || lower == "restaurant" {
            return ["Olive Garden", "Sushi Sake", "Chipotle", "Thai Express", "Five Guys", "Domino's Pizza", "Panda Express", "Texas Roadhouse"]
        }
        if lower == "study" || lower == "study spots" {
            return ["Library", "Coffee Shop", "Study Room", "Campus Cafe", "Quiet Lounge", "Study Hall", "Outdoor Patio", "Study Center"]
        }
        return ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]
    }
    
    private static func getMovieImageUrl(for movieName: String) -> String {
        let seed = abs(movieName.hashValue) % 1000
        return "https://picsum.photos/seed/movie\(seed)/400/300"
    }
    
    private static func getStudySpotImageUrl(for spotName: String) -> String {
        let seed = abs(spotName.hashValue) % 1000
        return "https://picsum.photos/seed/study\(seed)/400/300"
    }
}
