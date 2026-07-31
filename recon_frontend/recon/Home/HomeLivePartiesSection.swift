//
//  HomeLivePartiesSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The parties this member is still part of, with whose turn it is. Without
/// this the home screen cannot tell anyone that a friend is waiting on them.
///
/// Drawn as quiet rows rather than cards: the topic list above is the loud
/// thing on this screen, and only a party actually waiting on you gets an
/// accent.
struct HomeLivePartiesSection: View {

    // MARK: - Properties

    let parties: [PartySummaryDTO]
    let statusLine: (PartySummaryDTO) -> String
    let isYourTurn: (PartySummaryDTO) -> Bool

    // MARK: - Constants

    /// Home is a glance, not an inbox.
    private let visibleCount = 3

    private let dotSize: CGFloat = 7

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle

            ForEach(Array(parties.prefix(visibleCount).enumerated()), id: \.element.id) { index, party in
                row(for: party)

                if index < min(parties.count, visibleCount) - 1 {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
    }

    private var sectionTitle: some View {
        Text("Happening now")
            .font(Constants.Fonts.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.bottom, 10)
    }

    // MARK: - Supporting

    private func row(for party: PartySummaryDTO) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    isYourTurn(party)
                        ? Constants.Colors.orangePrimary
                        : Color.secondary.opacity(0.3)
                )
                .frame(width: dotSize, height: dotSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(party.title)
                    .font(Constants.Fonts.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(statusLine(party))
                    .font(Constants.Fonts.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Constants.Fonts.caption)
                .foregroundColor(Color.secondary.opacity(0.5))
        }
        .padding(.vertical, 12)
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
