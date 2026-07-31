//
//  HomeLivePartiesSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The parties this member is still part of, with whose turn it is. Without
/// this the home screen cannot tell anyone that a friend is waiting on them.
struct HomeLivePartiesSection: View {

    // MARK: - Properties

    let parties: [PartySummaryDTO]
    let statusLine: (PartySummaryDTO) -> String
    let isYourTurn: (PartySummaryDTO) -> Bool

    // MARK: - Constants

    /// Home is a glance, not an inbox. Anything older stays reachable from
    /// the party itself.
    private let visibleCount = 3

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Happening now")
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)

            ForEach(parties.prefix(visibleCount)) { party in
                card(for: party)
            }
        }
    }

    // MARK: - Supporting

    private func card(for party: PartySummaryDTO) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(party.title)
                    .font(Constants.Fonts.bodySemibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                if isYourTurn(party) {
                    turnPill
                }
            }

            Text(statusLine(party))
                .font(Constants.Fonts.label)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var turnPill: some View {
        Text("your turn")
            .font(Constants.Fonts.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Constants.Colors.orangePrimary)
            )
    }

}

#Preview {
    HomeLivePartiesSection(
        parties: [],
        statusLine: { _ in "3 cards left to swipe" },
        isYourTurn: { _ in true }
    )
    .padding()
    .background(Constants.Colors.background)
}
