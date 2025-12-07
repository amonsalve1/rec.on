//
//  RestaurantAPI.swift
//  recon
//
//  Created by Ethan Chen on 12/4/2024.
//

import Foundation
import CoreLocation
@preconcurrency import Alamofire

struct OSMElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let tags: OSMTags?
}

struct OSMTags: Codable {
    let name: String?
    let amenity: String?
    let cuisine: String?
    let addr_street: String?
    let addr_city: String?
    let addr_housenumber: String?
    let addr_postcode: String?
    let addr_state: String?
    let addr_country: String?
    let addr_full: String?
    let addr_place: String?
    let addr_suburb: String?
    
    enum CodingKeys: String, CodingKey {
        case name, amenity, cuisine
        case addr_street = "addr:street"
        case addr_city = "addr:city"
        case addr_housenumber = "addr:housenumber"
        case addr_postcode = "addr:postcode"
        case addr_state = "addr:state"
        case addr_country = "addr:country"
        case addr_full = "addr:full"
        case addr_place = "addr:place"
        case addr_suburb = "addr:suburb"
    }
}

struct OSMResponse: Codable {
    let elements: [OSMElement]
}

final class RestaurantAPI {
    static let shared = RestaurantAPI()
    private init() {}
    
    let overpassBaseURL = "https://overpass-api.de/api/interpreter"
    let pexelsAPIKey: String? = nil
    let pexelsBaseURL = "https://api.pexels.com/v1"
    
    struct RestaurantInfo: Codable {
        let name: String
        let imageUrl: String?
        let address: String
        let tags: [String]
    }
    
    func searchNearbyRestaurants(location: CLLocation, completion: @escaping (Result<[RestaurantInfo], Error>) -> Void) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let radius = 2000
        
        let query = """
        [out:json][timeout:25];
        (
          way["amenity"~"^(restaurant|fast_food|cafe)$"](around:\(radius),\(lat),\(lon));
          node["amenity"~"^(restaurant|fast_food|cafe)$"](around:\(radius),\(lat),\(lon));
        );
        out;
        """
        
        let parameters: [String: String] = ["data": query]
        
        AF.request(overpassBaseURL, method: .post, parameters: parameters, encoding: URLEncoding.httpBody)
            .validate()
            .responseDecodable(of: OSMResponse.self) { response in
                if case .success(let osmResponse) = response.result {
                    var infos: [RestaurantInfo] = []
                    var seen = Set<String>()
                    
                    for element in osmResponse.elements {
                        if let name = element.tags?.name, !name.isEmpty {
                            let normalized = name.trimmingCharacters(in: .whitespaces)
                            if !normalized.isEmpty && !seen.contains(normalized) {
                                let imageUrl = self.getRestaurantImageUrl(for: normalized)
                                let address = self.extractAddress(from: element.tags)
                                
                                var tags: [String] = []
                                if let cuisine = element.tags?.cuisine {
                                    tags.append(cuisine)
                                }
                                if let amenity = element.tags?.amenity {
                                    tags.append(amenity.capitalized)
                                }
                                
                                infos.append(RestaurantInfo(
                                    name: normalized,
                                    imageUrl: imageUrl,
                                    address: address,
                                    tags: tags
                                ))
                                seen.insert(normalized)
                            }
                        }
                    }
                    
                    let limited = Array(infos.prefix(8))
                    if limited.isEmpty {
                        completion(.failure(NSError(domain: "RestaurantAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No restaurants found"])))
                    } else {
                        completion(.success(limited))
                    }
                } else {
                    completion(.failure(response.error ?? NSError(domain: "RestaurantAPI", code: -1)))
                }
            }
    }
    
    func getRestaurantImageUrl(for restaurantName: String) -> String {
        let seed = abs(restaurantName.hashValue) % 1000
        return "https://picsum.photos/seed/restaurant\(seed)/400/300"
    }
    
    func fetchRestaurantImage(for restaurantName: String, completion: @escaping (String?) -> Void) {
        if pexelsAPIKey == nil {
            let encoded = restaurantName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? restaurantName
            completion("https://source.unsplash.com/featured/400x300/?restaurant,\(encoded),food")
            return
        }
        
        let query = "\(restaurantName) restaurant food"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = "\(pexelsBaseURL)/search?query=\(encoded)&per_page=1"
        
        var headers: HTTPHeaders = [:]
        headers["Authorization"] = pexelsAPIKey
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: PexelsResponse.self) { response in
                if case .success(let pexelsResponse) = response.result, let photo = pexelsResponse.photos.first {
                    completion(photo.src.medium)
                } else {
                    let encoded = restaurantName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? restaurantName
                    completion("https://source.unsplash.com/featured/400x300/?restaurant,\(encoded),food")
                }
            }
    }
    
    func extractAddress(from tags: OSMTags?) -> String {
        guard let tags = tags else { return "Address not available" }
        
        if let full = tags.addr_full, !full.isEmpty {
            return full
        }
        
        var parts: [String] = []
        
        if let house = tags.addr_housenumber, let street = tags.addr_street {
            parts.append("\(house) \(street)")
        } else if let street = tags.addr_street {
            parts.append(street)
        } else if let house = tags.addr_housenumber {
            parts.append(house)
        }
        
        if let suburb = tags.addr_suburb {
            parts.append(suburb)
        }
        
        if let city = tags.addr_city {
            parts.append(city)
        } else if let place = tags.addr_place {
            parts.append(place)
        }
        
        if let state = tags.addr_state {
            parts.append(state)
        }
        if let postcode = tags.addr_postcode {
            parts.append(postcode)
        }
        
        return parts.isEmpty ? "Address not available" : parts.joined(separator: ", ")
    }
}

struct PexelsResponse: Codable {
    let photos: [PexelsPhoto]
}

struct PexelsPhoto: Codable {
    let src: PexelsPhotoSizes
}

struct PexelsPhotoSizes: Codable {
    let original: String
    let large: String
    let medium: String
    let small: String
}
