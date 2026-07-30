//
//  OnboardingPageView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

/// A single page of the onboarding carousel: logo, optional emoji, headline,
/// and optional supporting text or bullets.
struct OnboardingPageView: View {

    // MARK: - Properties

    let page: OnboardingPage

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            logo

            if let emoji = page.emoji {
                Text(emoji)
                    .font(Constants.Fonts.emojiDisplay)
                    .padding(.bottom, 24)
            }

            headline

            if let smallText = page.smallText {
                Text(smallText)
                    .font(Constants.Fonts.bodyRegularRounded)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 16)
            }

            if let bulletPoints = page.bulletPoints {
                bullets(bulletPoints)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var logo: some View {
        Image("RecOnScriptLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 300)
            .padding(.bottom, 40)
    }

    private var headline: some View {
        Text(page.largeText)
            .font(Constants.Fonts.display)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.bottom, page.smallText != nil || page.bulletPoints != nil ? 16 : 0)
    }

    // MARK: - Supporting

    private func bullets(_ bulletPoints: [OnboardingPage.BulletPoint]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(bulletPoints) { bullet in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: bullet.icon)
                        .font(Constants.Fonts.iconSmall)
                        .foregroundColor(Constants.Colors.orangeLight)
                        .frame(width: 24)

                    Text(bullet.text)
                        .font(Constants.Fonts.bodyRegularRounded)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.top, 8)
    }

}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            emoji: "👋",
            largeText: "Meet your new inspiration!",
            smallText: "Swipe to decide. Remember what you like. Discover more.",
            bulletPoints: nil
        )
    )
    .background(Constants.Colors.surfaceDark)
}
