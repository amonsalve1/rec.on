//
//  OnboardingHelloPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/30/2026.
//

import SwiftUI

/// The first onboarding page: the brand moment. Script wordmark on the warm
/// gradient field, one line of promise, and a nudge to keep going.
struct OnboardingHelloPage: View {

    // MARK: - Constants

    private let logoWidth: CGFloat = 260
    private let logoTilt: Double = -4

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            logo

            squiggleAccent

            tagline

            Spacer()

            hint
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }

    private var logo: some View {
        Image("RecOnScriptLogo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(.white)
            .frame(width: logoWidth)
            .rotationEffect(.degrees(logoTilt))
    }

    private var squiggleAccent: some View {
        SquiggleShape()
            .stroke(
                Constants.Colors.ink.opacity(0.5),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
            .frame(width: 90, height: 12)
            .padding(.top, 20)
    }

    private var tagline: some View {
        Text("Deciding together,\nminus the group chat")
            .font(Constants.Fonts.title)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.top, 24)
    }

    private var hint: some View {
        Text("swipe to see how")
            .font(Constants.Fonts.bodyRegularRounded)
            .foregroundColor(.white.opacity(0.8))
    }

}

#Preview {
    OnboardingHelloPage()
        .background(
            LinearGradient(
                colors: [Constants.Colors.splashTop, Constants.Colors.splashBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}
