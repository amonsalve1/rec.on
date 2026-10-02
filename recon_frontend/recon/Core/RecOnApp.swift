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
                /// The canvas is a designed warm paper and every surface in the
                /// app is painted light. Following the system scheme only meant
                /// system-drawn chrome — keyboards, sheets, menus, alerts —
                /// arriving dark on top of it.
                .preferredColorScheme(.light)
        }
    }

}
