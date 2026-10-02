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
                .foregroundColor(Constants.Colors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 28)
    }

    private var finishButton: some View {
        PrimaryButton(title: "Let's decide", action: onFinish)
    }

}

#Preview {
    OnboardingReadyPage(onFinish: {})
        .background(Constants.Colors.background)
}
