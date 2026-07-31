//
//  WinnerPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Foundation

/// The final results step: celebrates the winning pick and saves it to the recent picks.
struct WinnerPage: View {

    // MARK: - Properties

    @State private var confetti = false

    @Environment(\.dismiss) private var dismiss

    let winner: PartyCandidate
    let onComplete: (() -> Void)?

    init(winner: PartyCandidate, onComplete: (() -> Void)? = nil) {
        self.winner = winner
        self.onComplete = onComplete
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            CanvasBackground()

            content

            ConfettiView(isActive: confetti)
        }
        .onAppear {
            confetti = true
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("We have a winner!")
                .font(Constants.Fonts.title)

            WinnerCard(winner: winner)

            Spacer()

            doneButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var doneButton: some View {
        Button {
            saveRecentPick(winner)
            onComplete?()
            NotificationCenter.default.post(name: .sessionFinished, object: nil)
        } label: {
            Text("Done")
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [
                                Constants.Colors.orangeLight,
                                Constants.Colors.orangePrimary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Helpers

    /// Persists the winner at the front of the recent picks list in UserDefaults.
    private func saveRecentPick(_ cand: PartyCandidate) {
        var picks: [RecentPickData] = []
        if let data = UserDefaults.standard.data(forKey: "recentPicks") {
            if let decoded = try? JSONDecoder().decode([RecentPickData].self, from: data) {
                picks = decoded
            }
        }

        let imageUrl = cand.imageUrl ?? cand.imageName
        let newPick = RecentPickData(
            id: Int(Date().timeIntervalSince1970),
            name: cand.name,
            imageUrl: imageUrl,
            address: cand.address,
            tags: cand.tags,
            timeAgo: "Just now"
        )

        picks.removeAll { $0.name == cand.name && abs($0.id - newPick.id) < 2 }

        picks.insert(newPick, at: 0)
        if picks.count > 20 {
            picks = Array(picks.prefix(20))
        }

        if let encoded = try? JSONEncoder().encode(picks) {
            UserDefaults.standard.set(encoded, forKey: "recentPicks")
            NotificationCenter.default.post(name: NSNotification.Name("RecentPicksUpdated"), object: nil)
        }
    }

}

#Preview {
    WinnerPage(
        winner: PartyCandidate(
            name: "Joe's Pizza",
            address: "7 Carmine St",
            tags: ["Pizza", "Casual"],
            imageName: "food1"
        )
    )
}
