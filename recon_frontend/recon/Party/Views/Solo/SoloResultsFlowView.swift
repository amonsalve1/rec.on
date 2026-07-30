//
//  SoloResultsFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Foundation

/// The solo results flow: the liked picks, the randomizer, and the winner reveal.
struct SoloResultsFlowView: View {

    // MARK: - Properties

    @State private var s = 0
    @State private var w: PartyCandidate?

    @Environment(\.dismiss) private var dismiss

    let candidates: [PartyCandidate]
    let onComplete: (() -> Void)?

    init(candidates: [PartyCandidate], onComplete: (() -> Void)? = nil) {
        self.candidates = candidates
        self.onComplete = onComplete
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            Constants.Colors.background.ignoresSafeArea()

            if candidates.isEmpty {
                emptyState
            } else {
                stepContent
            }
        }
        .navigationTitle(s == 0 ? "Picks" : "Solo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("No favorites selected")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Text("You didn't like any options.")
                .font(Constants.Fonts.label)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch s {
        case 0:
            PicksListPage(
                candidates: candidates,
                onConfirm: {
                    s = 1
                }
            )

        case 1:
            RandomizingPage(
                candidates: candidates,
                forced: nil,
                onFinished: { selected in
                    w = selected
                    s = 2
                }
            )

        case 2:
            if let w {
                WinnerPage(winner: w) {
                    onComplete?()
                }
            }

        default:
            EmptyView()
        }
    }

}

#Preview {
    NavigationStack {
        SoloResultsFlowView(
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
            ]
        )
    }
}
