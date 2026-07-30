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
        var imageUrl: String? = nil
        var address: String = ""
        var tags: [String] = []
        
        if let details = finalPick.option_details {
            if let url = details["image_url"] {
                imageUrl = url
            }
            
            if let addr = details["address"] {
                address = addr
            }
            
            if let tagsString = details["tags"],
               let tagsData = tagsString.data(using: .utf8),
               let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
                tags = decodedTags
            }
        }
        
        let backendId = Int(finalPick.option_id)
        
        self.init(
            backendId: backendId,
            name: finalPick.option_name,
            address: address,
            tags: tags,
            imageName: "food1",
            imageUrl: imageUrl
        )
    }
}
