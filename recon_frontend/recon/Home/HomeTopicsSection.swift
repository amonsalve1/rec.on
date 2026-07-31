//
//  HomeTopicsSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The primary action on the home screen: the things you can decide on,
/// offered directly rather than behind a solo/party menu.
struct HomeTopicsSection: View {

    // MARK: - Properties

    let topics: [HomeView.Topic]
    let onSelect: (HomeView.Topic) -> Void

    // MARK: - Constants

    private let tileSize: CGFloat = 38
    private let rowCorner: CGFloat = 16

    // MARK: - UI

    var body: some View {
        VStack(spacing: 10) {
            ForEach(topics) { topic in
                Button {
                    onSelect(topic)
                } label: {
                    row(for: topic)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Supporting

    private func row(for topic: HomeView.Topic) -> some View {
        HStack(spacing: 14) {
            iconTile(for: topic)

            Text(topic.title)
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(rowCorner)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func iconTile(for topic: HomeView.Topic) -> some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(tint(for: topic).opacity(0.18))
            .frame(width: tileSize, height: tileSize)
            .overlay(
                Image(systemName: topic.systemImage)
                    .font(Constants.Fonts.bodyLarge)
                    .foregroundColor(tint(for: topic))
            )
    }

    // MARK: - Helpers

    /// Each topic keeps its own tint so the rows are distinguishable at a
    /// glance instead of being three identical orange blocks.
    private func tint(for topic: HomeView.Topic) -> Color {
        switch topic.id {
        case "food":
            return Constants.Colors.orangePrimary
        case "study":
            return Constants.Colors.amber
        default:
            return Constants.Colors.peach
        }
    }

}

#Preview {
    HomeTopicsSection(
        topics: [
            .init(id: "food", title: "Food nearby", systemImage: "fork.knife"),
            .init(id: "study", title: "Study spots", systemImage: "books.vertical"),
            .init(id: "movie", title: "Movies", systemImage: "film")
        ],
        onSelect: { _ in }
    )
    .padding()
    .background(Constants.Colors.background)
}
