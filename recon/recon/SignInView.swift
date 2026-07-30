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

            VStack(spacing: 0) {
                titleBar

                Spacer()

                stepContent

                Spacer()

                progressDots
            }
        }
    }

    private var titleBar: some View {
        HStack {
            Text("Sign In")
                .font(Constants.Fonts.bodyLarge)
                .foregroundColor(Constants.Colors.ink)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, Constants.Padding.screenHorizontal)
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

    @ViewBuilder
    private var progressDots: some View {
        switch viewModel.currentStep {
        case .welcome:
            EmptyView()
        case .loading:
            SignInStepDots(total: viewModel.totalSteps, activeThrough: -1)
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
