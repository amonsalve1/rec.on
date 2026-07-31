//
//  HomePreviousPicksSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The user's recent final picks as compact rows. Cards were wider than the
/// names that had to fit in them, so every title truncated.
struct HomePreviousPicksSection: View {

    // MARK: - Properties

    let recentPicks: [FinalPick]
    let onSeeAll: () -> Void

    // MARK: - Constants

    private let thumbSize: CGFloat = 38
    private let visibleCount = 3

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if recentPicks.isEmpty {
                emptyLabel
            } else {
                ForEach(recentPicks.prefix(visibleCount)) { pick in
                    row(for: pick)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Recent")
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                onSeeAll()
            } label: {
                Text("See all")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.orangePrimary)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyLabel: some View {
        Text("Nothing decided yet")
            .font(Constants.Fonts.label)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }

    // MARK: - Supporting

    private func row(for pick: FinalPick) -> some View {
        HStack(spacing: 12) {
            OptionArtwork(
                name: pick.name,
                imageUrl: pick.imageUrl,
                initialSize: 18
            )
            .frame(width: thumbSize, height: thumbSize)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(pick.name)
                .font(Constants.Fonts.body)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            Text(pick.timeAgo)
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)
        }
    }

}

#Preview {
    HomePreviousPicksSection(
        recentPicks: [],
        onSeeAll: {}
    )
    .padding()
    .background(Constants.Colors.background)
}
