//
//  RecOnSplashView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

/// The black script-logo splash that plays before the onboarding carousel,
/// stretching the logo in and fading itself out.
struct RecOnSplashView: View {

    // MARK: - Properties

    @Binding var showSplash: Bool

    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0.0

    // MARK: - Constants

    private let logoWidth: CGFloat = 260
    private let fadeOutDelay: TimeInterval = 1.3

    // MARK: - UI

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            logo
        }
        .onAppear {
            animateIn()
        }
    }

    private var logo: some View {
        Image("RecOnScriptLogo")
            .resizable()
            .scaledToFit()
            .frame(width: logoWidth)
            .scaleEffect(x: scale, y: 1.0)
            .opacity(opacity)
    }

    // MARK: - Helpers

    /// Stretches the logo in, settles it, then fades out and dismisses.
    private func animateIn() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            scale = 1.05
            opacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.35).delay(0.6)) {
            scale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDelay) {
            withAnimation(.easeInOut(duration: 0.4)) {
                opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showSplash = false
            }
        }
    }

}

#Preview {
    RecOnSplashView(showSplash: .constant(true))
}
