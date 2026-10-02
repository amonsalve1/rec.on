//
//  PasswordView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

/// The wizard step asking for the password and submitting the request.
struct PasswordView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SignInView.ViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            SignInBackButton {
                viewModel.goBackFromPassword()
            }

            Spacer()

            BrandWordmark(width: 104)

            VStack(spacing: 20) {
                Text("What's your password?")
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
                    title: "Confirm",
                    isEnabled: !viewModel.password.isEmpty
                ) {
                    viewModel.submitPassword()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var field: some View {
        SignInField {
            SecureField("", text: $viewModel.password, prompt: signInPrompt("Password"))
                .textContentType(.password)
                .onChange(of: viewModel.password) { _, _ in
                    viewModel.errorMessage = nil
                }
        }
    }

}

#Preview {
    PasswordView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
