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
    
    func refreshAccessToken(completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let token = APIConfig.refreshToken
        if token.isEmpty {
            completion(.failure(NSError(domain: "RecOnAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])))
            return
        }
        
        let url = APIConfig.baseURL.appendingPathComponent("refresh/")
        session.request(url, method: .post, headers: [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ])
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            if (200..<300).contains(statusCode), let data = response.data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    UserDefaults.standard.set(token, forKey: "authToken")
                    completion(.success(token))
                    return
                }
                
                if let str = String(data: data, encoding: .utf8),
                   let jsonData = str.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let token = json["token"] as? String {
                    UserDefaults.standard.set(token, forKey: "authToken")
                    completion(.success(token))
                    return
                }
                
                completion(.failure(RecOnAPIError.noData))
            } else {
                APIConfig.clearAuthToken()
                let msg = self.extractErrorMessage(from: response.data, statusCode: statusCode)
                completion(.failure(NSError(domain: "RecOnAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
            }
        }
    }
    
    func isTokenExpired(statusCode: Int, errorData: Data?) -> Bool {
        guard statusCode == 401 else { return false }
        
        guard let data = errorData else { return false }
        let str = String(data: data, encoding: .utf8) ?? ""
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let msg = (json["msg"] as? String ?? json["error"] as? String)?.lowercased() ?? ""
            if msg.contains("token has expired") || msg.contains("token expired") {
                return true
            }
        }
        
        if str.lowercased().contains("token has expired") || str.lowercased().contains("token expired") {
            return true
        }
        
        return false
    }
    
    func extractErrorMessage(from data: Data?, statusCode: Int) -> String {
        guard let data = data else { return "HTTP \(statusCode)" }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["msg"] as? String ?? json["error"] as? String {
            return msg
        }
        
        let str = String(data: data, encoding: .utf8) ?? ""
        if let jsonData = str.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let msg = json["msg"] as? String ?? json["error"] as? String {
            return msg
        }
        
        return str.count < 200 ? str : "HTTP \(statusCode)"
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
