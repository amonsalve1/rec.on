//
//  HomeTopicsSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The primary action on the home screen, drawn as a deck you scroll through
/// rather than a settings list. The app is about swiping cards, so the first
/// thing on the screen is cards.
struct HomeTopicsSection: View {

    // MARK: - Properties

    let topics: [HomeView.Topic]
    let onSelect: (HomeView.Topic) -> Void

    // MARK: - Constants

    private let cardWidth: CGFloat = 168
    private let cardHeight: CGFloat = 212
    private let corner: CGFloat = 26

    // MARK: - UI

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(topics) { topic in
                    Button {
                        onSelect(topic)
                    } label: {
                        card(for: topic)
                    }
                    .buttonStyle(PressableCard())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
        }
        .scrollClipDisabled()
    }

    // MARK: - Supporting

    private func card(for topic: HomeView.Topic) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: corner)
                .fill(gradient(for: topic))

            // oversized glyph bleeding off the corner, as texture
            Image(systemName: topic.systemImage)
                .font(.system(size: 96, weight: .semibold))
                .foregroundColor(.white.opacity(0.16))
                .offset(x: 58, y: -46)

            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: topic.systemImage)
                    .font(Constants.Fonts.subheading)
                    .foregroundColor(.white)

                Spacer()

                Text(topic.title)
                    .font(Constants.Fonts.subheading)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle(for: topic))
                    .font(Constants.Fonts.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(18)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .shadow(color: shadowTint(for: topic), radius: 12, x: 0, y: 6)
    }

    // MARK: - Helpers

    private func gradient(for topic: HomeView.Topic) -> LinearGradient {
        let stops: [Color]
        switch topic.id {
        case "food":
            stops = [Constants.Colors.orangeLight, Constants.Colors.orangePrimary]
        case "study":
            stops = [Constants.Colors.amber, Constants.Colors.orangeLight]
        default:
            // movies get the dark card, which anchors the warm palette
            stops = [Constants.Colors.surfaceDark, Constants.Colors.ink]
        }
        return LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func shadowTint(for topic: HomeView.Topic) -> Color {
        topic.id == "movie"
            ? Color.black.opacity(0.22)
            : Constants.Colors.orangePrimary.opacity(0.28)
    }

    private func subtitle(for topic: HomeView.Topic) -> String {
        switch topic.id {
        case "food":
            return "Places near you"
        case "study":
            return "Somewhere to sit"
        default:
            return "Something to watch"
        }
    }

}

/// Cards dip slightly when pressed, so the deck feels physical.
struct PressableCard: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
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
    .padding(.vertical)
    .background(Constants.Colors.background)
}
