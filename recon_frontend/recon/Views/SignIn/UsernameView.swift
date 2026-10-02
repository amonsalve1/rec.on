//
//  UsernameView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

/// The sign-up wizard step asking for a username.
struct UsernameView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SignInView.ViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            SignInBackButton {
                viewModel.goBackFromUsername()
            }

            Spacer()

            BrandWordmark(width: 104)

            VStack(spacing: 20) {
                Text("Pick a username")
                    .font(Constants.Fonts.heading)
                    .foregroundColor(Constants.Colors.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 36)

                field

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Constants.Fonts.bodySmall)
                        .foregroundColor(Constants.Colors.danger)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(
                    title: "Next",
                    isEnabled: !viewModel.username.isEmpty
                ) {
                    viewModel.advanceFromUsername()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var field: some View {
        SignInField {
            TextField("", text: $viewModel.username, prompt: signInPrompt("username"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)
                /// Only clear the error as the name GROWS: retyping after a
                /// "taken" response should keep the message until the value
                /// actually differs from the one that was rejected.
                .onChange(of: viewModel.username) { oldValue, newValue in
                    if oldValue != newValue && newValue.count > oldValue.count {
                        viewModel.errorMessage = nil
                    }
                }
        }
    }

}

#Preview {
    UsernameView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
