//
//  PartyResultsFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct PartyResultsFlowView: View {
    let candidates: [PartyCandidate]
    let backendWinner: PartyCandidate?
    let onComplete: (() -> Void)?

    @State private var step = 0
    @State private var winner: PartyCandidate?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

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
        .navigationTitle(step == 0 ? "Picks" : "Party")
        .navigationBarTitleDisplayMode(.inline)
    }
}
