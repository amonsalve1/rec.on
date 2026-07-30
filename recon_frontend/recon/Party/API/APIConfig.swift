//
//  APIConfig.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/2/2024.
//

import Foundation

extension Notification.Name {
    static let tokenExpired = Notification.Name("tokenExpired")
}

struct APIConfig {
    static let baseURL = URL(string: "http://34.21.78.117")!

    /// Non-secret flag the UI observes to gate signed-in state; the tokens
    /// themselves live in the Keychain and are never in UserDefaults.
    static var hasSession: Bool {
        UserDefaults.standard.bool(forKey: "hasSession")
    }

    static var authToken: String {
        TokenStore.accessToken ?? ""
    }

    static var refreshToken: String {
        TokenStore.refreshToken ?? ""
    }

    static func setTokens(accessToken: String, refreshToken: String) {
        TokenStore.save(accessToken: accessToken, refreshToken: refreshToken)
        UserDefaults.standard.set(true, forKey: "hasSession")
    }

    static func clearAuthToken() {
        TokenStore.clear()
        UserDefaults.standard.set(false, forKey: "hasSession")
        NotificationCenter.default.post(name: .tokenExpired, object: nil)
    }
}
