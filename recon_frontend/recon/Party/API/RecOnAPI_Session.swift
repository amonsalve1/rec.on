//
//  RecOnAPI_Session.swift
//  recon
//
//  Created by Ethan Chen on 12/3/2024.
//

import Foundation
@preconcurrency import Alamofire

extension RecOnAPI {
    func createParty(title: String, topic: String, location: CreatePartyRequest.Location?, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        if APIConfig.authToken.isEmpty {
            completion(.failure(NSError(domain: "RecOnAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated. Please log in first."])))
            return
        }

        let url = endpoint("parties")
        let body = CreatePartyRequest(title: title, topic: topic, location: location)
        session.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                completion(.success(envelope.party))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.createParty(title: title, topic: topic, location: location, completion: completion)
                }, completion: completion)
            }
        }
    }

    /// The caller's live parties, for the home screen.
    func listParties(completion: @escaping @Sendable (Result<[PartySummaryDTO], Error>) -> Void) {
        guard !APIConfig.authToken.isEmpty else {
            completion(.success([]))
            return
        }

        let url = endpoint("parties")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(PartyListEnvelope.self, from: data) {
                completion(.success(envelope.parties))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.listParties(completion: completion)
                }, completion: completion)
            }
        }
    }

    func joinParty(code: String, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        let url = endpoint("parties/join")
        session.request(
            url,
            method: .post,
            parameters: ["invite_code": code],
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                completion(.success(envelope.party))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.joinParty(code: code, completion: completion)
                }, completion: completion)
            }
        }
    }

    func getSession(sessionId: String, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                completion(.success(envelope.party))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getSession(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }

    func getOptions(sessionId: String, completion: @escaping @Sendable (Result<[OptionDTO], Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/options")
        session.request(url, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(OptionsEnvelope.self, from: data) {
                completion(.success(envelope.options))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.getOptions(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }

    /// Host-only: moves the party from lobby to swiping.
    func startParty(sessionId: String, completion: @escaping @Sendable (Result<SessionDTO, Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/start")
        session.request(url, method: .post, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(SessionEnvelope.self, from: data) {
                completion(.success(envelope.party))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.startParty(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }

    /// Host-only: mints the party's invite code. The plaintext code exists
    /// only in this response — the backend stores an HMAC.
    func mintInvite(sessionId: String, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        let url = endpoint("parties/\(sessionId)/invite")
        session.request(url, method: .post, headers: headers)
        .responseData { response in
            let statusCode = response.response?.statusCode ?? -1

            if (200..<300).contains(statusCode), let data = response.data,
               let envelope = try? JSONDecoder().decode(InviteEnvelope.self, from: data),
               let code = envelope.invite.code {
                completion(.success(code))
            } else {
                self.handleTokenRefresh(statusCode: statusCode, errorData: response.data, retry: {
                    self.mintInvite(sessionId: sessionId, completion: completion)
                }, completion: completion)
            }
        }
    }
}
