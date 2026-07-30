//
//  WelcomeView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

/// The sign-in landing step with the logo and the two mode buttons.
struct WelcomeView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SignInView.ViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            logo

            Text("Recommend On the go.")
                .font(Constants.Fonts.bodyLarge)
                .foregroundColor(.gray)
                .padding(.top, 16)

            Spacer()
                .frame(height: 80)

            modeButtons

            SignInStepDots(total: 3, activeThrough: 0)
        }
    }

    private var logo: some View {
        Image("RecOnLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
    }

    private var modeButtons: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.begin(.signUp)
            } label: {
                Text("Get Started")
                    .font(Constants.Fonts.buttonLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Constants.Colors.accent)
                    .cornerRadius(22)
            }

            Button {
                viewModel.begin(.signIn)
            } label: {
                Text("Sign In")
                    .font(Constants.Fonts.buttonLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Constants.Colors.accent.opacity(0.9))
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 50)
    }

}

#Preview {
    WelcomeView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
