//
//  HomeLivePartiesSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The parties this member is still part of. Each carries a ring showing how
/// far through the deck they are, so progress is something you see rather
/// than read.
struct HomeLivePartiesSection: View {

    // MARK: - Properties

    let parties: [PartySummaryDTO]
    let statusLine: (PartySummaryDTO) -> String
    let isYourTurn: (PartySummaryDTO) -> Bool
    let onSelect: (PartySummaryDTO) -> Void
    let onLeave: (PartySummaryDTO) -> Void

    // MARK: - Constants

    /// Home is a glance, not an inbox.
    private let visibleCount = 3

    private let ringSize: CGFloat = 42

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Happening now")
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(parties.prefix(visibleCount)) { party in
                    // a plain tap target rather than a Button: a Button would
                    // swallow the horizontal drag that reveals Leave
                    card(for: party)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(party)
                        }
                        .swipeActionsCompat {
                            onLeave(party)
                        }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Supporting

    private func card(for party: PartySummaryDTO) -> some View {
        HStack(spacing: 14) {
            progressRing(for: party)

            VStack(alignment: .leading, spacing: 3) {
                Text(party.title)
                    .font(Constants.Fonts.bodySemibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(statusLine(party))
                    .font(Constants.Fonts.label)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isYourTurn(party) {
                Text("your turn")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.orangePrimary)
            }

            Image(systemName: "chevron.right")
                .font(Constants.Fonts.caption)
                .foregroundColor(Color.secondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func progressRing(for party: PartySummaryDTO) -> some View {
        ZStack {
            Circle()
                .stroke(Constants.Colors.orangePrimary.opacity(0.15), lineWidth: 4)

            Circle()
                .trim(from: 0, to: fraction(for: party))
                .stroke(
                    Constants.Colors.orangePrimary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: glyph(for: party))
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.ink.opacity(0.7))
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - Helpers

    /// How far this member is through the deck, 0 when the party is still in
    /// its lobby.
    private func fraction(for party: PartySummaryDTO) -> CGFloat {
        guard party.optionCount > 0, party.state != "lobby" else { return 0 }
        return min(CGFloat(party.viewer.swipedCount) / CGFloat(party.optionCount), 1)
    }

    /// The party's topic, so a glance at the ring says what it is about.
    private func glyph(for party: PartySummaryDTO) -> String {
        switch party.topic {
        case "restaurant":
            return "fork.knife"
        case "activity":
            return "books.vertical"
        default:
            return "film"
        }
    }

}

#Preview {
    HomeLivePartiesSection(
        parties: [],
        statusLine: { _ in "3 cards left to swipe" },
        isYourTurn: { _ in true },
        onSelect: { _ in },
        onLeave: { _ in }
    )
    .padding(.vertical)
    .background(Constants.Colors.background)
}
