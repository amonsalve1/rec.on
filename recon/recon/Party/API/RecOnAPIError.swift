//
//  RecOnAPIError.swift
//  recon
//
//  Created by Ethan Chen on 12/2/2024.
//

import Foundation

enum RecOnAPIError: Error, LocalizedError {
    case invalidURL
    case noSessionId
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .noSessionId: return "No session id available."
        case .noData: return "No data returned from server."
        }
    }
}

