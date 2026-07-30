//
//  RecOnApp.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/25/2024.
//

import SwiftUI

/// The app entry point.
@main
struct RecOnApp: App {

    // MARK: - Init

    init() {
        TokenStore.bootstrap()
    }

    // MARK: - UI

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

}
