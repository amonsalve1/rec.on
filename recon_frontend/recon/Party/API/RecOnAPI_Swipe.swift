//
//  RecOnAPI_Swipe.swift
//  recon
//
//  Created by Ethan Chen on 12/3/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func recordSwipe(sessionId: String, optionId: Int, liked: Bool, completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        let url = endpoint("parties/\(sessionId)/swipes")
        let body = RecordSwipeRequest(option_id: optionId, liked: liked)
        session.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode) {
                completion?(.success(()))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.recordSwipe(sessionId: sessionId, optionId: optionId, liked: liked, completion: completion)
                }, completion: { result in
                    completion?(result)
                })
            }
        }
    }

    /// The caller's own swipes, for rebuilding the liked list.
    func getMySwipes(sessionId: String, completion: @escaping @Sendable (Result<[SwipeDTO], Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/swipes/me")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode([String: [SwipeDTO]].self, from: data) {
                completion(.success(envelope["swipes"] ?? []))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getMySwipes(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
}
