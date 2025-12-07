//
//  OnboardingModels.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/1/2024.
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let emoji: String?
    let largeText: String
    let smallText: String?
    let bulletPoints: [BulletPoint]?
    
    struct BulletPoint: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
    }
}

