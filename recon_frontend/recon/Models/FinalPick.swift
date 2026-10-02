//
//  FinalPick.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

/// A past winner, shown in the recent picks list.
struct FinalPick: Identifiable {

    // MARK: - Properties

    let id: Int
    let name: String
    let imageUrl: String
    let address: String
    let tags: [String]
    let timeAgo: String

    // MARK: - Init

    init(
        id: Int,
        name: String,
        imageUrl: String,
        address: String,
        tags: [String],
        timeAgo: String
    ) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.address = address
        self.tags = tags
        self.timeAgo = timeAgo
    }

    init(from dto: RecentPickDTO) {
        self.id = dto.id
        self.name = dto.name
        self.imageUrl = dto.imageUrl
        self.address = dto.address
        self.tags = dto.tags
        self.timeAgo = dto.timeAgo
    }

}
