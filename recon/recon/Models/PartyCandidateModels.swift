//
//  PartyCandidateModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct PartyCandidate: Identifiable, Equatable {
    let id = UUID()
    let backendId: Int?
    let name: String
    let address: String
    let tags: [String]
    let imageName: String
    let imageUrl: String?

    init(backendId: Int? = nil,
         name: String,
         address: String,
         tags: [String],
         imageName: String,
         imageUrl: String? = nil) {
        self.backendId = backendId
        self.name = name
        self.address = address
        self.tags = tags
        self.imageName = imageName
        self.imageUrl = imageUrl
    }
}
