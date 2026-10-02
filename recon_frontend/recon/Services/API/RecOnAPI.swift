//
//  RecOnAPI.swift
//  recon
//
//  Created by Ethan Chen on 12/2/2024.
//

import Foundation
@preconcurrency import Alamofire

final class RecOnAPI: @unchecked Sendable {
    static nonisolated let shared = RecOnAPI()
    var baseURL: URL { APIConfig.baseURL }
    private init() {}

    let session = Session.default

    var headers: HTTPHeaders {
        [
            "Authorization": "Bearer \(APIConfig.authToken)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    /// Builds a URL under the versioned API root.
    func endpoint(_ path: String) -> URL {
        APIConfig.baseURL.appendingPathComponent("v1/\(path)")
    }

    /// Rotates the refresh token. The backend invalidates the old refresh
    /// token on every rotation, so BOTH returned tokens must be stored —
    /// keeping the old refresh token would trip reuse detection and revoke
    /// the whole session family.
    func refreshAccessToken(completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let token = APIConfig.refreshToken
        if token.isEmpty {
            completion(.failure(NSError(domain: "RecOnAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])))
            return
        }

        let url = endpoint("auth/refresh")
        session.request(
            url,
            method: .post,
            parameters: ["refresh_token": token],
            encoding: JSONEncoding.default,
            headers: ["Content-Type": "application/json", "Accept": "application/json"]
        )
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            if (200..<300).contains(statusCode), let data = response.data,
               let payload = try? JSONDecoder().decode(LoginResponse.self, from: data),
               let access = payload.tokenValue,
               let refresh = payload.refreshToken {
                APIConfig.setTokens(accessToken: access, refreshToken: refresh)
                completion(.success(access))
            } else {
                APIConfig.clearAuthToken()
                let msg = self.extractErrorMessage(from: response.data, statusCode: statusCode)
                completion(.failure(NSError(domain: "RecOnAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
            }
        }
    }

    /// The backend's error envelope: {"error": {"code": ..., "message": ...}}.
    func errorPayload(from data: Data?) -> (code: String?, message: String?) {
        guard
            let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = json["error"] as? [String: Any]
        else {
            return (nil, nil)
        }
        return (error["code"] as? String, error["message"] as? String)
    }

    func isTokenExpired(statusCode: Int, errorData: Data?) -> Bool {
        guard statusCode == 401 else { return false }
        return errorPayload(from: errorData).code == "token_expired"
    }

    func extractErrorMessage(from data: Data?, statusCode: Int) -> String {
        if let message = errorPayload(from: data).message {
            return message
        }

        guard let data = data else { return "HTTP \(statusCode)" }
        let str = String(data: data, encoding: .utf8) ?? ""
        return str.count < 200 && !str.isEmpty ? str : "HTTP \(statusCode)"
    }

    func handleTokenRefresh<T>(statusCode: Int, errorData: Data?, retry: @escaping () -> Void, completion: @escaping (Result<T, Error>) -> Void) {
        if isTokenExpired(statusCode: statusCode, errorData: errorData) {
            let token = APIConfig.refreshToken
            if token.isEmpty {
                APIConfig.clearAuthToken()
                completion(.failure(NSError(domain: "RecOnAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Your session has expired. Please log in again."])))
                return
            }

            refreshAccessToken { result in
                if case .success = result {
                    retry()
                } else {
                    APIConfig.clearAuthToken()
                    completion(.failure(NSError(domain: "RecOnAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Your session has expired. Please log in again."])))
                }
            }
        } else {
            let msg = self.extractErrorMessage(from: errorData, statusCode: statusCode)
            completion(.failure(NSError(domain: "RecOnAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
        }
    }
}
