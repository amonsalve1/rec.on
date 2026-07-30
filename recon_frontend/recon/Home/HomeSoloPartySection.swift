//
//  HomeSoloPartySection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The home card offering the two entry points into a session: solo or party.
struct HomeSoloPartySection: View {

    // MARK: - Constants

    private let cardCornerRadius: CGFloat = 24
    private let buttonCornerRadius: CGFloat = 18
    private let buttonHeight: CGFloat = 120

    // MARK: - UI

    var body: some View {
        ZStack {
            card

            VStack(alignment: .leading, spacing: 16) {
                title

                buttons
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, -16)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private var title: some View {
        Text("What do you reckon's next?")
            .font(Constants.Fonts.subheading)
    }

    private var buttons: some View {
        HStack(spacing: 16) {
            NavigationLink {
                SoloFlowView()
            } label: {
                modeButtonLabel("Solo")
            }

            NavigationLink {
                PartySetupView()
            } label: {
                modeButtonLabel("Party")
            }
        }
    }

    // MARK: - Supporting

    private func modeButtonLabel(_ title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: buttonCornerRadius)
                .fill(Constants.Colors.accent)

            Text(title)
                .font(Constants.Fonts.subheading)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: buttonHeight)
    }

}

#Preview {
    NavigationStack {
        HomeSoloPartySection()
            .padding()
    }
}
