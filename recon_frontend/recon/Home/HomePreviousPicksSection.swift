//
//  HomePreviousPicksSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// What has been decided lately, as a strip of artwork. This is the only
/// place in the app that shows a run of past winners, so it earns pictures.
struct HomePreviousPicksSection: View {

    // MARK: - Properties

    let recentPicks: [FinalPick]
    let onSeeAll: () -> Void

    // MARK: - Constants

    private let tileSize: CGFloat = 96

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if recentPicks.isEmpty {
                emptyLabel
            } else {
                strip
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Recent")
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

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
        .padding(.horizontal, 24)
    }

    private var emptyLabel: some View {
        Text("Nothing decided yet")
            .font(Constants.Fonts.label)
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
    }

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(recentPicks) { pick in
                    tile(for: pick)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    // MARK: - Supporting

    private func tile(for pick: FinalPick) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            OptionArtwork(
                name: pick.name,
                imageUrl: pick.imageUrl,
                initialSize: 34
            )
            .frame(width: tileSize, height: tileSize)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)

            Text(pick.name)
                .font(Constants.Fonts.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: tileSize, alignment: .leading)
        }
    }

}

#Preview {
    HomePreviousPicksSection(
        recentPicks: [],
        onSeeAll: {}
    )
    .padding(.vertical)
    .background(Constants.Colors.background)
}
