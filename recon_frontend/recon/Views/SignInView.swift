//
//  SignInView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/26/2024.
//

import SwiftUI

/// The sign-in flow: a step wizard that walks through email, username (for
/// sign-up), and password before handing the session to RootView.
struct SignInView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    // MARK: - UI

    var body: some View {
        ZStack {
            Constants.Colors.background
                .ignoresSafeArea()

            /// No title bar: it read "Sign In" on every step including the
            /// one offering Get Started, and each step already states its own
            /// question. The dots carry position instead.
            VStack(spacing: 0) {
                stepContent

                progressDots
                    .padding(.bottom, 28)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeView(viewModel: viewModel)
        case .email:
            EmailView(viewModel: viewModel)
        case .username:
            UsernameView(viewModel: viewModel)
        case .password:
            PasswordView(viewModel: viewModel)
        case .loading:
            LoadingView()
        }
    }

    /// Welcome and the loading interstitial are not steps you can be part way
    /// through, so neither shows a position. This is the only place the dots
    /// are drawn.
    @ViewBuilder
    private var progressDots: some View {
        switch viewModel.currentStep {
        case .welcome, .loading:
            EmptyView()
        default:
            SignInStepDots(
                total: viewModel.totalSteps,
                activeThrough: viewModel.stepIndex
            )
        }
    }

}

#Preview {
    SignInView()
}
