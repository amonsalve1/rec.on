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

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            FannedCards()

            title

            Spacer()

            finishButton
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
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

}

#Preview {
    OnboardingReadyPage(onFinish: {})
        .background(Constants.Colors.background)
}
