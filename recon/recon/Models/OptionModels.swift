//
//  OptionModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct OptionDTO: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let address: String?
    let tags: [String]?
    let image_url: String?
}

