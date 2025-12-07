//
//  SignInModels.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import Foundation

enum SignInStep {
    case welcome
    case email
    case username
    case password
    case loading
}

enum AuthMode {
    case signUp
    case signIn
}

