//
//  SwipeModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct RecordSwipeRequest: Encodable, Sendable {
    let session_id: Int
    let option_id: Int
    let option_name: String
    let direction: String
}

struct SubmitFinalPickRequest: Encodable, Sendable {
    let session_id: Int
    let option_id: Int
    let option_name: String
    let option_details: [String: String]?
}

struct FinalPickDTO: Codable, Sendable {
    let id: Int
    let session_id: Int
    let user_id: Int
    let option_id: String
    let option_name: String
    let option_details: [String: String]?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case id, session_id, user_id, option_id, option_name, option_details, username
    }
}

struct ProgressDTO: Codable, Sendable {
    let user_id: Int
    let username: String
    let swipe_count: Int
    let total_options: Int
}

