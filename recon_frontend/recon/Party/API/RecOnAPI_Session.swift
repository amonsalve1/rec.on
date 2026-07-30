//
//  RecOnAPI_Session.swift
//  recon
//
//  Created by Ethan Chen on 12/3/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func createSession(topic: String, options: [String], completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        if APIConfig.authToken.isEmpty {
            completion(.failure(NSError(domain: "RecOnAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated. Please log in first."])))
            return
        }
        
        let url = APIConfig.baseURL.appendingPathComponent("create/")
        let type: String
        switch topic.lowercased() {
        case "food nearby", "food": type = "restaurant"
        case "movies", "movie": type = "movie"
        case "study spots", "activity", "activities": type = "activity"
        default: type = "restaurant"
        }
        
        let body = CreateSessionRequest(name: "session", type_session: type, options: options)
        session.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data, !data.isEmpty {
                if let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                    completion(.success(envelope.session))
                } else if let session = try? JSONDecoder().decode(SessionDTO.self, from: data) {
                    completion(.success(session))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.createSession(topic: topic, options: options, completion: completion)
                }, completion: completion)
            }
        }
    }
    
    func joinSession(sessionId: Int, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("\(sessionId)/join/")
        session.request(url, method: .post, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                if let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                    completion(.success(envelope.session))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.joinSession(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
    
    func getSession(sessionId: Int, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("session").appendingPathComponent("\(sessionId)/")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                if let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                    completion(.success(envelope.session))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getSession(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
    
    func getOptions(sessionId: Int, completion: @escaping (Result<[BackendOption], Error>) -> Void) {
        getSession(sessionId: sessionId) { result in
            completion(result.map { $0.options })
        }
    }
}
