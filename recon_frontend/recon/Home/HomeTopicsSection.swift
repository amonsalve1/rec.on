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
            Image(topic.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)

            // brand tint over the photo, deepening toward the caption so the
            // type stays legible whatever the picture is doing
            LinearGradient(
                colors: [
                    tint(for: topic).opacity(0.15),
                    tint(for: topic).opacity(0.55),
                    Constants.Colors.ink.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

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

    /// Each photo gets its own tint so the three cards stay distinguishable
    /// while sharing one treatment.
    private func tint(for topic: HomeView.Topic) -> Color {
        switch topic.id {
        case "food":
            return Constants.Colors.orangePrimary
        case "study":
            return Constants.Colors.amber
        default:
            return Constants.Colors.surfaceDark
        }
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
            .init(id: "food", title: "Food nearby", systemImage: "fork.knife", imageName: "TopicFood"),
            .init(id: "study", title: "Study spots", systemImage: "books.vertical", imageName: "TopicStudy"),
            .init(id: "movie", title: "Movies", systemImage: "film", imageName: "TopicMovie")
        ],
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(Constants.Colors.background)
}
