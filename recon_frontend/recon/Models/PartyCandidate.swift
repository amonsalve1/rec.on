//
//  PartyCandidate.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

/// One option on the swipe deck, as the UI sees it.
///
/// `id` is a fresh UUID per instance so SwiftUI can diff the deck, which means
/// two candidates for the same place are never equal by identity. Compare
/// `backendId` when you need to know whether two candidates are the same
/// option; it is nil only for locally seeded options that never came from the
/// server.
struct PartyCandidate: Identifiable, Equatable {

    // MARK: - Properties

    let id = UUID()

    /// The server's option id, or nil for a locally built candidate.
    let backendId: Int?
    let name: String
    let address: String
    let tags: [String]
    let imageName: String
    let imageUrl: String?

    // MARK: - Init

    init(
        backendId: Int? = nil,
        name: String,
        address: String,
        tags: [String],
        imageName: String,
        imageUrl: String? = nil
    ) {
        self.backendId = backendId
        self.name = name
        self.address = address
        self.tags = tags
        self.imageName = imageName
        self.imageUrl = imageUrl
    }

    init(from option: OptionDTO) {
        self.init(
            backendId: option.id,
            name: option.name,
            address: option.address ?? "",
            tags: option.tags ?? [],
            imageName: "food1",
            imageUrl: option.image_url
        )
    }

    init(from finalPick: FinalPickDTO) {
        self.init(from: finalPick.option)
    }

}
