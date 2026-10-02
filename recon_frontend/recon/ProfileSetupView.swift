//
//  ProfileSetupView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The step after sign-up that collects a display name and an optional
/// location before the app opens.
struct ProfileSetupView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    // MARK: - UI

    var body: some View {
        ZStack {
            /// This screen was the one surface still painting itself pure
            /// white, which made the jump from sign-in to onboarding look like
            /// a jump between two different apps.
            Constants.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                BrandWordmark(width: 104)

                VStack(spacing: 20) {
                    Text("Tell us about yourself")
                        .font(Constants.Fonts.heading)
                        .foregroundColor(Constants.Colors.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 36)

                    nameField

                    locationField

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(Constants.Fonts.bodySmall)
                            .foregroundColor(Constants.Colors.danger)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(
                        title: "Continue",
                        isEnabled: !viewModel.name.isEmpty,
                        isLoading: viewModel.isLoading
                    ) {
                        Task { await viewModel.saveProfile() }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    private var nameField: some View {
        SignInField {
            TextField("", text: $viewModel.name, prompt: signInPrompt("Your name"))
                .textContentType(.name)
                .onChange(of: viewModel.name) { _, _ in
                    viewModel.errorMessage = nil
                }
        }
    }

    private var locationField: some View {
        SignInField {
            TextField("", text: $viewModel.location, prompt: signInPrompt("Your location (optional)"))
                .textContentType(.addressCityAndState)
                .onChange(of: viewModel.location) { _, _ in
                    viewModel.errorMessage = nil
                }
        }
    }

}

#Preview {
    ProfileSetupView()
}
