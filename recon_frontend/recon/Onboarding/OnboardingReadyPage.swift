//
//  OnboardingReadyPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/30/2026.
//

import SwiftUI

/// The final onboarding page: fanned cards hint at the group mechanic, and
/// the button hands over to the app.
struct OnboardingReadyPage: View {

    // MARK: - Properties

    /// Called when the user is done with onboarding.
    let onFinish: () -> Void

    // MARK: - Constants

    private let cardSize = CGSize(width: 72, height: 96)

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            fannedCards

            title

            Spacer()

            finishButton
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }

    private var fannedCards: some View {
        HStack(spacing: -14) {
            miniCard(fill: Constants.Colors.orangeLight, tilt: -10)

            miniCard(fill: Constants.Colors.orangePrimary, tilt: 0)
                .offset(y: -10)
                .zIndex(1)

            miniCard(fill: Constants.Colors.peach, tilt: 10)
        }
    }

    private var title: some View {
        VStack(spacing: 8) {
            Text("Your friends pick too")
                .font(Constants.Fonts.title)
                .multilineTextAlignment(.center)

            Text("Everyone swipes, everyone picks a favorite,\nand the fairest option wins.")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 28)
    }

    private var finishButton: some View {
        Button {
            onFinish()
        } label: {
            Text("Let's decide")
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Constants.Colors.orangeLight,
                                    Constants.Colors.orangePrimary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
    }

    // MARK: - Supporting

    private func miniCard(fill: Color, tilt: Double) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(fill)
            .frame(width: cardSize.width, height: cardSize.height)
            .rotationEffect(.degrees(tilt))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

}

#Preview {
    OnboardingReadyPage(onFinish: {})
        .background(Constants.Colors.background)
}
