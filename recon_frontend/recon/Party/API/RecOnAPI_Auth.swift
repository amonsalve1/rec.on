//
//  RecOnAPI_Auth.swift
//  recon
//
//  Created by Ethan Chen on 12/2/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func register(email: String, username: String, password: String, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let url = endpoint("auth/register")
        let body: [String: String] = ["email": email, "username": username, "password": password]
        session.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json", "Accept": "application/json"])
        .responseData { response in
            self.handleAuthResponse(response, completion: completion)
        }
    }

    func login(email: String, password: String, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let url = endpoint("auth/login")
        let body: [String: String] = ["email": email, "password": password]
        session.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json", "Accept": "application/json"])
        .responseData { response in
            self.handleAuthResponse(response, completion: completion)
        }
    }

    /// Register and login share a response shape: user + token pair. Stores
    /// both tokens and hands back the access token.
    private func handleAuthResponse(_ response: AFDataResponse<Data>, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let statusCode = response.response?.statusCode ?? -1

        if (200..<300).contains(statusCode), let data = response.data {
            if let payload = try? JSONDecoder().decode(LoginResponse.self, from: data),
               let access = payload.tokenValue {
                if let refresh = payload.refreshToken {
                    APIConfig.setTokens(accessToken: access, refreshToken: refresh)
                } else {
                    TokenStore.saveAccessToken(access)
                    UserDefaults.standard.set(true, forKey: "hasSession")
                }
                completion(.success(access))
            } else {
                completion(.failure(RecOnAPIError.noData))
            }
        } else {
            let msg = extractErrorMessage(from: response.data, statusCode: statusCode)
            completion(.failure(NSError(domain: "RecOnAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
        }
    }
}
