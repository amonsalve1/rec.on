//
//  PartyBackendModels.swift
//  recon
//
//  Created by Ethan Chen on 12/1/2024.
//

import Foundation

extension PartyCandidate {
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
