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

    static var authToken: String {
        UserDefaults.standard.string(forKey: "authToken") ?? ""
    }
    
    static var refreshToken: String {
        UserDefaults.standard.string(forKey: "refreshToken") ?? ""
    }
    
    static func setTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: "authToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
    }
    
    static func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        NotificationCenter.default.post(name: .tokenExpired, object: nil)
    }
}

