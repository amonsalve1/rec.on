//
//  RandomizingPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Combine

/// The animated randomizer step that cycles through the candidates before landing on the winner.
struct RandomizingPage: View {

    // MARK: - Properties

    @State private var i = 0
    @State private var wIdx = 0
    @State private var ticks = 0
    @State private var run = true

    let candidates: [PartyCandidate]
    let forced: PartyCandidate?
    let onFinished: (PartyCandidate) -> Void

    private let timer = Timer
        .publish(every: 0.18, on: .main, in: .common)
        .autoconnect()

    // MARK: - UI

    var body: some View {
        VStack(spacing: 32) {
            Text("Randomizing...")
                .font(.system(size: 26, weight: .bold, design: .rounded))

            carousel

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .onAppear {
            pickWinnerIndex()
        }
        .onReceive(timer) { _ in
            advance()
        }
    }

    private var carousel: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {
                if candidates.count > 1 {
                    RandCard(
                        candidate: candidates[prev],
                        center: false
                    )
                    .frame(width: geo.size.width * 0.28)
                }

                RandCard(
                    candidate: candidates[i],
                    center: true
                )
                .frame(width: geo.size.width * 0.36)

                if candidates.count > 1 {
                    RandCard(
                        candidate: candidates[next],
                        center: false
                    )
                    .frame(width: geo.size.width * 0.28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 200)
    }

    // MARK: - Helpers

    private var prev: Int {
        (i - 1 + candidates.count) % candidates.count
    }

    private var next: Int {
        (i + 1) % candidates.count
    }

    /// Chooses the landing index up front, honoring a backend-forced winner when present.
    private func pickWinnerIndex() {
        guard !candidates.isEmpty else { return }

        if let forced = forced,
           let found = candidates.firstIndex(of: forced) {
            wIdx = found
        } else {
            wIdx = Int.random(in: 0..<candidates.count)
        }
    }

    /// Advances the carousel one card per tick and stops once it lands on the winner.
    private func advance() {
        guard run, !candidates.isEmpty else { return }

        ticks += 1
        i = (i + 1) % candidates.count

        let minTicks = candidates.count * 3

        if ticks >= minTicks && i == wIdx {
            run = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onFinished(candidates[wIdx])
            }
        }
    }

}

#Preview {
    RandomizingPage(
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
        forced: nil
    ) { _ in }
}
