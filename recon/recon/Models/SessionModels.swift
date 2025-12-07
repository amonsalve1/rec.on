//
//  SessionModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct BackendOption: Codable, Sendable {
    let id: Int
    let text: String
}

struct ParticipantDTO: Codable, Identifiable, Sendable {
    let id: Int
    let username: String?
    let email: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let idValue = try? container.decode(Int.self) {
            self.id = idValue
            self.username = nil
            self.email = nil
            return
        }
        
        let objectContainer = try decoder.container(keyedBy: CodingKeys.self)
        id = try objectContainer.decode(Int.self, forKey: .id)
        username = try objectContainer.decodeIfPresent(String.self, forKey: .username)
        email = try objectContainer.decodeIfPresent(String.self, forKey: .email)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
    }
}

struct WinnerDTO: Codable, Sendable {
    let option_id: String?
    let option_name: String?
    let option_details: [String: String]?
    let picked_by: String?
    let picked_by_user_id: Int?
}

struct SessionDTO: Codable, Sendable {
    let id: Int
    let name: String
    let typeSession: String
    let createdBy: Int
    let status: String
    let options: [BackendOption]
    let winner: WinnerDTO?
    let participants: [ParticipantDTO]?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, status, options, winner, participants
        case typeSession = "type_session"
        case createdBy   = "created_by"
        case createdAt   = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        typeSession = try container.decode(String.self, forKey: .typeSession)
        createdBy = try container.decode(Int.self, forKey: .createdBy)
        status = try container.decode(String.self, forKey: .status)
        options = try container.decodeIfPresent([BackendOption].self, forKey: .options) ?? []
        winner = try container.decodeIfPresent(WinnerDTO.self, forKey: .winner)
        participants = try container.decodeIfPresent([ParticipantDTO].self, forKey: .participants)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

struct SessionEnvelope: Codable, Sendable {
    let session: SessionDTO
}

struct CreateSessionRequest: Encodable, Sendable {
    let name: String
    let type_session: String
    let options: [String]
}

