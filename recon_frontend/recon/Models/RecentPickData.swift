//
//  RecentPickData.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

/// A recent pick as persisted locally. Kept separate from `FinalPick` because
/// this one has to stay `Codable` for the UserDefaults round trip.
struct RecentPickData: Codable, Identifiable {

    // MARK: - Properties

    let id: Int
    let name: String
    let imageUrl: String
    let address: String
    let tags: [String]
    let timeAgo: String

}
