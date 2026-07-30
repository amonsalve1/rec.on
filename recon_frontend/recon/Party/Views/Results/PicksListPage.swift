//
//  PicksListPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The first results step: the pooled list of everyone's picks with a confirm button.
struct PicksListPage: View {

    // MARK: - Properties

    let candidates: [PartyCandidate]
    let onConfirm: () -> Void

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            picksList

            Spacer()

            confirmButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pool of picks")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("One pick from each person")
                    .font(Constants.Fonts.label)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(candidates.count) picks")
                .font(Constants.Fonts.labelMedium)
                .foregroundColor(.secondary)
        }
    }

    private var picksList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(candidates) { cand in
                    PickCard(candidate: cand)
                }
            }
            .padding(.top, 8)
        }
    }

    private var confirmButton: some View {
        Button {
            onConfirm()
        } label: {
            Text("Confirm")
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Constants.Colors.orangeLight, Constants.Colors.orangePrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

}

#Preview {
    PicksListPage(
        candidates: [
            PartyCandidate(
                name: "Joe's Pizza",
                address: "7 Carmine St",
                tags: ["Pizza", "Casual"],
                imageName: "food1"
            ),
            PartyCandidate(
                name: "Thai Villa",
                address: "5 E 19th St",
                tags: ["Thai", "Cozy"],
                imageName: "food1"
            )
        ],
        onConfirm: {}
    )
    .background(Constants.Colors.background)
}
