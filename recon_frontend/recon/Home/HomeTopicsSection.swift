//
//  HomeTopicsSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The primary action on the home screen: the things you can decide on,
/// offered directly rather than behind a solo/party menu.
///
/// One grouped card holding hairline-separated rows, so the section reads as
/// a single object instead of three competing tiles.
struct HomeTopicsSection: View {

    // MARK: - Properties

    let topics: [HomeView.Topic]
    let onSelect: (HomeView.Topic) -> Void

    // MARK: - Constants

    private let iconWidth: CGFloat = 26

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                Button {
                    onSelect(topic)
                } label: {
                    row(for: topic)
                }
                .buttonStyle(.plain)

                if index < topics.count - 1 {
                    Divider()
                        .padding(.leading, 58)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Supporting

    private func row(for topic: HomeView.Topic) -> some View {
        HStack(spacing: 16) {
            Image(systemName: topic.systemImage)
                .font(Constants.Fonts.bodyLarge)
                .foregroundColor(Constants.Colors.orangePrimary)
                .frame(width: iconWidth)

            Text(topic.title)
                .font(Constants.Fonts.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(Constants.Fonts.caption)
                .foregroundColor(Color.secondary.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .contentShape(Rectangle())
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
