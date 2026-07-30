//
//  SwipeModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct RecordSwipeRequest: Encodable, Sendable {
    let option_id: Int
    let liked: Bool
}

/// One of the caller's own swipes, from GET swipes/me.
struct SwipeDTO: Codable, Sendable {
    let option_id: Int
    let liked: Bool
}

struct SubmitFinalPickRequest: Encodable, Sendable {
    let option_id: Int
}

/// One member's final pick, carrying the full option the backend stored.
struct FinalPickDTO: Codable, Sendable {
    let user_id: Int
    let username: String?
    let display_name: String?
    let option: OptionDTO
}

/// One member's swipe progress for the waiting screen. Assembled client-side
/// from the progress endpoint's per-member entries plus its option_count.
struct ProgressDTO: Codable, Sendable {
    let user_id: Int
    let username: String
    let swipe_count: Int
    let total_options: Int
}
