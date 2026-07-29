//
//  HomePreviousPicksSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The horizontally scrolling strip of the user's recent final picks, with a
/// "See all" pill that jumps to the profile.
struct HomePreviousPicksSection: View {

    // MARK: - Properties

    let recentPicks: [FinalPick]
    let onSeeAll: () -> Void

    // MARK: - Constants

    private let cardWidth: CGFloat = 110
    private let cardHeight: CGFloat = 80
    private let cardCornerRadius: CGFloat = 12

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleRow

            picksRow
        }
    }

    private var titleRow: some View {
        HStack {
            Text("Your previous picks")
                .font(Constants.Fonts.sectionTitle)

            Spacer()

            seeAllButton
        }
    }

    private var seeAllButton: some View {
        Button {
            onSeeAll()
        } label: {
            Capsule()
                .fill(Constants.Colors.accent)
                .frame(width: 80, height: 32)
                .overlay(
                    Text("See all")
                        .font(Constants.Fonts.labelMedium)
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var picksRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                if recentPicks.isEmpty {
                    emptyLabel
                } else {
                    ForEach(recentPicks) { pick in
                        pickCard(for: pick)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var emptyLabel: some View {
        Text("No recent picks yet")
            .font(Constants.Fonts.label)
            .foregroundColor(.secondary)
            .padding(.vertical, 20)
    }

    // MARK: - Supporting

    private func pickCard(for pick: FinalPick) -> some View {
        VStack(spacing: 8) {
            pickImage(for: pick)
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))

            Text(pick.name)
                .font(Constants.Fonts.cardTitle)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: cardWidth, alignment: .center)
        }
    }

    @ViewBuilder
    private func pickImage(for pick: FinalPick) -> some View {
        if let url = URL(string: pick.imageUrl), pick.imageUrl.hasPrefix("http") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    fallbackArt
                @unknown default:
                    fallbackArt
                }
            }
        } else {
            fallbackArt
        }
    }

    private var fallbackArt: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Constants.Colors.orangeLight,
                        Constants.Colors.orangePrimary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

}

#Preview {
    HomePreviousPicksSection(
        recentPicks: [],
        onSeeAll: {}
    )
    .padding()
}
