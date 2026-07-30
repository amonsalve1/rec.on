//
//  RecentPicksStore.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Foundation

/// Loads the locally persisted recent final picks that the home and profile
/// screens both display.
enum RecentPicksStore {

    // MARK: - Helpers

    /// Decodes the persisted picks from UserDefaults, or an empty list if
    /// nothing valid is stored.
    static func load() -> [FinalPick] {
        guard
            let data = UserDefaults.standard.data(forKey: "recentPicks"),
            let decoded = try? JSONDecoder().decode([RecentPickData].self, from: data)
        else {
            return []
        }

        return decoded.map { pickData in
            FinalPick(
                id: pickData.id,
                name: pickData.name,
                imageUrl: pickData.imageUrl,
                address: pickData.address,
                tags: pickData.tags,
                timeAgo: pickData.timeAgo
            )
        }
    }

}
