//
//  RecOnAPI_Swipe.swift
//  recon
//
//  Created by Ethan Chen on 12/3/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func recordSwipe(sessionId: Int, optionId: Int, optionName: String, liked: Bool, completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        let url = APIConfig.baseURL.appendingPathComponent("swipes/")
        let body = RecordSwipeRequest(session_id: sessionId, option_id: optionId, option_name: optionName, direction: liked ? "like" : "dislike")
        session.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode) {
                completion?(.success(()))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.recordSwipe(sessionId: sessionId, optionId: optionId, optionName: optionName, liked: liked, completion: completion)
                }, completion: { result in
                    completion?(result)
                })
            }
        }
    }
    
    func getLikedOptions(sessionId: Int, completion: @escaping @Sendable (Result<[BackendOption], Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("\(sessionId)/liked/")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1
            
            if (200..<300).contains(statusCode), let data = response.data {
                if let envelope = try? JSONDecoder().decode([String: [BackendOption]].self, from: data) {
                    completion(.success(envelope["liked_options"] ?? []))
                } else {
                    completion(.failure(RecOnAPIError.noData))
                }
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getLikedOptions(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
}
