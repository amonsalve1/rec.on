//
//  SessionModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

/// One member of a party, as serialized by the backend's member_dict.
struct ParticipantDTO: Codable, Identifiable, Sendable, Hashable {
    let userId: Int
    let username: String?
    let displayName: String?
    let role: String?
    let joinedAt: String?

    var id: Int { userId }

    var isHost: Bool { role == "host" }

    enum CodingKeys: String, CodingKey {
        case username, role
        case userId = "user_id"
        case displayName = "display_name"
        case joinedAt = "joined_at"
    }
}

/// A party as serialized by the backend's party_dict. Kept under the old
/// SessionDTO name so the flow code reads the same.
struct SessionDTO: Codable, Sendable {
    let id: String
    let title: String
    let topic: String
    let state: String
    let version: Int
    let hostUserId: Int
    let optionCount: Int
    let memberCount: Int
    let submittedCount: Int
    let winner: OptionDTO?
    let members: [ParticipantDTO]

    /// Legacy accessors, so call sites written against the old API read on.
    var createdBy: Int { hostUserId }
    var status: String { state }
    var participants: [ParticipantDTO]? { members }

    enum CodingKeys: String, CodingKey {
        case id, title, topic, state, version, winner, members
        case hostUserId = "host_user_id"
        case optionCount = "option_count"
        case memberCount = "member_count"
        case submittedCount = "submitted_count"
    }
}

struct SessionEnvelope: Codable, Sendable {
    let party: SessionDTO
}

/// A live party as it appears in the caller's list, with the viewer's own
/// progress attached so the home screen can say whose turn it is.
struct PartySummaryDTO: Codable, Sendable, Identifiable, Hashable {
    struct Viewer: Codable, Sendable, Hashable {
        let swipedCount: Int
        let hasPicked: Bool

        enum CodingKeys: String, CodingKey {
            case swipedCount = "swiped_count"
            case hasPicked = "has_picked"
        }
    }

    let id: String
    let title: String
    let topic: String
    let state: String
    let optionCount: Int
    let memberCount: Int
    let submittedCount: Int
    let members: [ParticipantDTO]
    let viewer: Viewer

    enum CodingKeys: String, CodingKey {
        case id, title, topic, state, members, viewer
        case optionCount = "option_count"
        case memberCount = "member_count"
        case submittedCount = "submitted_count"
    }
}

struct PartyListEnvelope: Codable, Sendable {
    let parties: [PartySummaryDTO]
}

struct OptionsEnvelope: Codable, Sendable {
    let options: [OptionDTO]
}

struct InviteEnvelope: Codable, Sendable {
    struct Invite: Codable, Sendable {
        let code: String?
    }

    let invite: Invite
}

struct CreatePartyRequest: Encodable, Sendable {
    struct Location: Encodable, Sendable {
        let lat: Double
        let lon: Double
    }

    let title: String
    let topic: String
    let location: Location?
}
