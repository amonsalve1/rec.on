//
//  PartyResultsFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The three-step party results flow: the pooled picks, the randomizer, and the winner reveal.
struct PartyResultsFlowView: View {

    // MARK: - Properties

    @State private var step = 0
    @State private var winner: PartyCandidate?

    let candidates: [PartyCandidate]
    let backendWinner: PartyCandidate?
    let onComplete: (() -> Void)?

    // MARK: - UI

    var body: some View {
        ZStack {
            Constants.Colors.background.ignoresSafeArea()

            stepContent
        }
        .navigationTitle(step == 0 ? "Picks" : "Party")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var stepContent: some View {
        if step == 0 {
            PicksListPage(candidates: candidates) {
                step = 1
            }
        } else if step == 1 {
            RandomizingPage(candidates: candidates, forced: backendWinner) { picked in
                winner = picked
                step = 2
            }
        } else if let winner = winner {
            WinnerPage(winner: winner, onComplete: onComplete)
        }
    }

}

#Preview {
    NavigationStack {
        PartyResultsFlowView(
            candidates: [
                PartyCandidate(
                    name: "Joe's Pizza",
                    address: "7 Carmine St",
                    tags: ["Pizza", "Casual"],
                    imageName: "food1"
                ),
                PartyCandidate(
                    name: "Thai Villa",
                    address: "5 E 19th St",
                    tags: ["Thai", "Cozy"],
                    imageName: "food1"
                )
            ],
            backendWinner: nil,
            onComplete: nil
        )
    }
}
