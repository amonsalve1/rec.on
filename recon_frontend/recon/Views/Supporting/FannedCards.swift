//
//  FannedCards.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/30/2026.
//

import SwiftUI

/// Three brand-tinted cards fanned like a hand — the app's motif for "a deck
/// of options", used in onboarding and end-of-deck states.
struct FannedCards: View {

    // MARK: - Properties

    var cardSize = CGSize(width: 72, height: 96)

    // MARK: - UI

    var body: some View {
        HStack(spacing: -14) {
            card(fill: Constants.Colors.orangeLight, tilt: -10)

            card(fill: Constants.Colors.orangePrimary, tilt: 0)
                .offset(y: -10)
                .zIndex(1)

            card(fill: Constants.Colors.peach, tilt: 10)
        }
    }

    // MARK: - Supporting

    private func card(fill: Color, tilt: Double) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(fill)
            .frame(width: cardSize.width, height: cardSize.height)
            .rotationEffect(.degrees(tilt))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

}

#Preview {
    FannedCards()
        .padding()
        .background(Constants.Colors.background)
}
