//
//  SplashView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/25/2024.
//

import SwiftUI

/// The orange launch splash shown before onboarding, animating the logo in
/// and dismissing itself after a short delay.
struct SplashView: View {

    // MARK: - Properties

    @Binding var showSplash: Bool

    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    // MARK: - Constants

    private let logoWidth: CGFloat = 180
    private let dismissDelay: TimeInterval = 1.2

    // MARK: - UI

    var body: some View {
        ZStack {
            background

            logo
        }
        .onAppear {
            animateIn()
        }
    }

    private var background: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Constants.Colors.splashTop,
                Constants.Colors.splashBottom
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var logo: some View {
        Image("RecOnLogo")
            .resizable()
            .scaledToFit()
            .frame(width: logoWidth)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    // MARK: - Helpers

    /// Springs the logo in, then flips `showSplash` off after the delay.
    private func animateIn() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            withAnimation {
                showSplash = false
            }
        }
    }

}

#Preview {
    SplashView(showSplash: .constant(true))
}
