//
//  RecOnAPI_Pick.swift
//  recon
//
//  Created by Ethan Chen on 12/3/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func submitFinalPick(sessionId: String, optionId: Int, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/picks")
        let body = SubmitFinalPickRequest(option_id: optionId)
        session.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode) {
                completion(.success(()))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.submitFinalPick(sessionId: sessionId, optionId: optionId, completion: completion)
                }, completion: { result in
                    completion(result)
                })
            }
        }
    }

    func getAllFinalPicks(sessionId: String, completion: @escaping @Sendable (Result<[FinalPickDTO], Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/picks")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(PicksEnvelope.self, from: data) {
                completion(.success(envelope.picks))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getAllFinalPicks(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }

    func getProgress(sessionId: String, completion: @escaping @Sendable (Result<[ProgressDTO], Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/progress")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(ProgressEnvelope.self, from: data) {
                let rows = envelope.progress.map { entry in
                    ProgressDTO(
                        user_id: entry.user_id,
                        username: entry.username,
                        swipe_count: entry.swiped_count,
                        total_options: envelope.option_count
                    )
                }
                completion(.success(rows))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getProgress(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }

    /// Asks the backend to draw the winner. Idempotent server-side, so
    /// racing clients all receive the same completed party.
    func spinWheel(sessionId: String, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/spin")
        session.request(url, method: .post, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                completion(.success(envelope.party))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.spinWheel(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
}

/// Wire shapes private to the pick endpoints.
struct PicksEnvelope: Codable, Sendable {
    let picks: [FinalPickDTO]
}

struct ProgressEnvelope: Codable, Sendable {
    struct Entry: Codable, Sendable {
        let user_id: Int
        let username: String
        let swiped_count: Int
        let has_picked: Bool
    }

    let progress: [Entry]
    let option_count: Int
}
