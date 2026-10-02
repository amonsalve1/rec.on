//
//  APIConfig.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/2/2024.
//

import Foundation

extension Notification.Name {
    static let tokenExpired = Notification.Name("tokenExpired")

    /// Posted when a solo or party session finishes. The flow roots listen
    /// and unwind themselves, so the exit does not depend on a chain of
    /// nested completion closures reaching all the way back up.
    static let sessionFinished = Notification.Name("sessionFinished")
}

struct APIConfig {
    /// The API root, injected per build configuration from
    /// Config/Debug.xcconfig or Config/Release.xcconfig via Info.plist.
    /// Debug points at a local backend; Release is HTTPS-only.
    static let baseURL: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "RecOnAPIBaseURL") as? String,
           let url = URL(string: raw),
           url.scheme != nil {
            return url
        }
        return URL(string: "http://localhost:5000")!
    }()

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
