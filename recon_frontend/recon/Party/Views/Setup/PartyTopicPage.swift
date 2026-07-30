//
//  PartyTopicPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI

/// The first party setup page, where the host picks the topic everyone will
/// swipe on.
struct PartyTopicPage: View {

    // MARK: - Properties

    let onTopicSelected: (String) -> Void

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            commonPicks
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text("What are you\nthinking?")
                .font(Constants.Fonts.display)

            Spacer()

            Text("🤔")
                .font(.system(size: 40))
        }
    }

    private var commonPicks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common picks")
                .font(Constants.Fonts.bodySemibold)

            VStack(spacing: 10) {
                TopicBtn(title: "Food nearby") {
                    onTopicSelected("food")
                }

                TopicBtn(title: "Study spots") {
                    onTopicSelected("study")
                }

                TopicBtn(title: "Movies") {
                    onTopicSelected("movie")
                }
            }
        }
    }

}

/// A full-width gradient pill button for a single topic pick.
struct TopicBtn: View {

    // MARK: - Properties

    let title: String
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [
                            Constants.Colors.orangeLight,
                            Constants.Colors.orangePrimary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    PartyTopicPage { _ in }
}
