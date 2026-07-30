//
//  UserModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct UserProfileDTO: Codable, Sendable {
    let id: Int
    let username: String?
    let name: String
    let email: String?
    let location: String?
    let profilePictureUrl: String?
    let friendsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, username, name, email, location
        case profilePictureUrl = "profile_picture_url"
        case friendsCount = "friends_count"
    }
}

struct LoginResponse: Decodable, Sendable {
    let accessToken: String?
    let token: String?
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case token
        case refreshToken = "refresh_token"
    }
    
    var tokenValue: String? {
        accessToken ?? token
    }
}

struct RecentPickDTO: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let imageUrl: String
    let address: String
    let tags: [String]
    let timeAgo: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "restaurant_name"
        case imageUrl = "image_url"
        case address
        case tags
        case timeAgo = "time_ago"
    }
}

