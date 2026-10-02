//
//  LocalProfile.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

/// The signed-in user's profile as the app holds it in memory.
struct LocalProfile {

    // MARK: - Properties

    let name: String
    let location: String
    let friendsCount: Int
    let profilePictureUrl: String?

}
