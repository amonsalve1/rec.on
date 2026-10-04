//
//  WelcomeView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

/// The sign-in landing step with the wordmark and the two mode buttons.
struct WelcomeView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SignInView.ViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            BrandWordmark(width: 232)

            Text("Recommend on the go.")
                .font(Constants.Fonts.bodyLarge)
                .foregroundColor(Constants.Colors.inkSecondary)
                .padding(.top, 18)

            Spacer()

            modeButtons
        }
    }

    /// One primary action and one quiet one, so a first-time visitor can
    /// tell at a glance which of the two is meant for them.
    private var modeButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Get Started") {
                viewModel.begin(.signUp)
            }

            Button {
                viewModel.begin(.signIn)
            } label: {
                Text("I already have an account")
                    .font(Constants.Fonts.bodySemibold)
                    .foregroundColor(Constants.Colors.orangePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }

}

#Preview {
    WelcomeView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
