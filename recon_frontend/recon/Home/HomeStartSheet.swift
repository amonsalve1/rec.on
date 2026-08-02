//
//  HomeStartSheet.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// Asked once, after a topic is chosen: alone or with friends. Keeping this
/// as a sheet is what lets the home screen offer topics directly instead of
/// making solo and party the first decision.
struct HomeStartSheet: View {

    // MARK: - Properties

    let topic: HomeView.Topic
    let onSolo: () -> Void
    let onParty: () -> Void

    // MARK: - UI

    var body: some View {
        VStack(spacing: 20) {
            Text(topic.title)
                .font(Constants.Fonts.heading)
                .padding(.top, 28)

            HStack(spacing: 12) {
                choice(
                    title: "Just me",
                    systemImage: "person.fill",
                    fill: Constants.Colors.amber,
                    action: onSolo
                )

                choice(
                    title: "With friends",
                    systemImage: "person.2.fill",
                    fill: Constants.Colors.orangePrimary,
                    action: onParty
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Supporting

    private func choice(
        title: String,
        systemImage: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(Constants.Fonts.iconLarge)

                Text(title)
                    .font(Constants.Fonts.bodySemibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(fill)
            )
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    HomeStartSheet(
        topic: .init(id: "food", title: "Food nearby", systemImage: "fork.knife"),
        onSolo: {},
        onParty: {}
    )
}
