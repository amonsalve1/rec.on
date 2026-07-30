//
//  TokenStore.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/30/2026.
//

import Foundation
import Security

/// Keychain-backed storage for the auth token pair.
///
/// Tokens used to live in UserDefaults, which is a plaintext plist on disk
/// and lands in unencrypted backups. Generic-password keychain items are
/// encrypted at rest and gated on device unlock. `bootstrap()` migrates any
/// tokens still sitting in UserDefaults and deletes them there.
enum TokenStore {

    // MARK: - Properties

    private static let service = "me.recon.tokens"
    private static let accessAccount = "access_token"
    private static let refreshAccount = "refresh_token"

    static var accessToken: String? {
        read(account: accessAccount)
    }

    static var refreshToken: String? {
        read(account: refreshAccount)
    }

    // MARK: - Helpers

    /// Stores both tokens, replacing whatever was there.
    static func save(accessToken: String, refreshToken: String) {
        write(account: accessAccount, value: accessToken)
        write(account: refreshAccount, value: refreshToken)
    }

    /// Stores a new access token without touching the refresh token.
    static func saveAccessToken(_ token: String) {
        write(account: accessAccount, value: token)
    }

    /// Removes both tokens.
    static func clear() {
        delete(account: accessAccount)
        delete(account: refreshAccount)
    }

    /// One-time migration from the old UserDefaults storage. Call at launch,
    /// before anything reads a token.
    static func bootstrap() {
        let defaults = UserDefaults.standard

        if let legacyAccess = defaults.string(forKey: "authToken"), !legacyAccess.isEmpty {
            write(account: accessAccount, value: legacyAccess)
            defaults.set(true, forKey: "hasSession")
        }
        if let legacyRefresh = defaults.string(forKey: "refreshToken"), !legacyRefresh.isEmpty {
            write(account: refreshAccount, value: legacyRefresh)
        }

        defaults.removeObject(forKey: "authToken")
        defaults.removeObject(forKey: "refreshToken")
    }

    // MARK: - Keychain plumbing

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard
            status == errSecSuccess,
            let data = item as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return value
    }

    private static func write(account: String, value: String) {
        let data = Data(value.utf8)
        var query = baseQuery(account: account)

        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private static func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

}
