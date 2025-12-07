//
//  RecOnAPI_Pick.swift
//  recon
//
//  Created by Ethan Chen on 12/3/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func submitFinalPick(sessionId: Int, optionId: Int, optionName: String, optionDetails: [String: String]? = nil, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("fpicks/")
        let body = SubmitFinalPickRequest(session_id: sessionId, option_id: optionId, option_name: optionName, option_details: optionDetails)
        session.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode) {
                completion(.success(()))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.submitFinalPick(sessionId: sessionId, optionId: optionId, optionName: optionName, optionDetails: optionDetails, completion: completion)
                }, completion: { result in
                    completion(result)
                })
            }
        }
    }
    
    func getAllFinalPicks(sessionId: Int, completion: @escaping @Sendable (Result<[FinalPickDTO], Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("picks").appendingPathComponent("\(sessionId)/")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                if let envelope = try? JSONDecoder().decode([String: [FinalPickDTO]].self, from: data) {
                    completion(.success(envelope["final_picks"] ?? []))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getAllFinalPicks(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
    
    func getProgress(sessionId: Int, completion: @escaping @Sendable (Result<[ProgressDTO], Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("\(sessionId)/progress/")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                if let envelope = try? JSONDecoder().decode([String: [ProgressDTO]].self, from: data) {
                    completion(.success(envelope["progress"] ?? []))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getProgress(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
    
    func spinWheel(sessionId: Int, completion: @escaping @Sendable (Result<[String: Any], Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("\(sessionId)/spin/")
        session.request(url, method: .post, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                let result = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                completion(.success(result))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.spinWheel(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
}
