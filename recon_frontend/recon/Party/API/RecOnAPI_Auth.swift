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
        let url = APIConfig.baseURL.appendingPathComponent("register/")
        let body: [String: String] = ["email": email, "username": username, "password": password]
        session.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json", "Accept": "application/json"])
        .validate(statusCode: 200..<300)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    let refreshToken = json["refresh_token"] as? String
                    if let refresh = refreshToken {
                        APIConfig.setTokens(accessToken: token, refreshToken: refresh)
                    } else {
                        UserDefaults.standard.set(token, forKey: "authToken")
                    }
                    completion(.success(token))
                    return
                }
                
                if let str = String(data: data, encoding: .utf8),
                   let jsonData = str.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let token = json["token"] as? String {
                    let refreshToken = json["refresh_token"] as? String
                    if let refresh = refreshToken {
                        APIConfig.setTokens(accessToken: token, refreshToken: refresh)
                    } else {
                        UserDefaults.standard.set(token, forKey: "authToken")
                    }
                    completion(.success(token))
                    return
                }
                
                if let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data),
                   let token = loginResponse.tokenValue {
                    if let refresh = loginResponse.refreshToken {
                        APIConfig.setTokens(accessToken: token, refreshToken: refresh)
                    } else {
                        UserDefaults.standard.set(token, forKey: "authToken")
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                let msg = self.extractErrorMessage(from: response.data, statusCode: statusCode)
                completion(.failure(NSError(domain: "RecOnAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("login/")
        let body: [String: String] = ["email": email, "password": password]
        session.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json", "Accept": "application/json"])
        .validate()
        .responseDecodable(of: LoginResponse.self) { response in
            if let loginResponse = try? response.result.get(),
               let token = loginResponse.tokenValue {
                if let refresh = loginResponse.refreshToken {
                    APIConfig.setTokens(accessToken: token, refreshToken: refresh)
                } else {
                    UserDefaults.standard.set(token, forKey: "authToken")
                }
                completion(.success(token))
            } else {
                completion(.failure(response.error ?? RecOnAPIError.noData))
            }
        }
    }
}
