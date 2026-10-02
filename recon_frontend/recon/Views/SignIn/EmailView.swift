//
//  EmailView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

/// The wizard step asking for the user's email.
struct EmailView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SignInView.ViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            SignInBackButton {
                viewModel.goBackFromEmail()
            }

            Spacer()

            BrandWordmark(width: 104)

            VStack(spacing: 20) {
                Text("What's your email?")
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
                    isEnabled: !viewModel.email.isEmpty
                ) {
                    viewModel.advanceFromEmail()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var field: some View {
        SignInField {
            TextField("", text: $viewModel.email, prompt: signInPrompt("email@example.com"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .onChange(of: viewModel.email) { _, _ in
                    viewModel.errorMessage = nil
                }
        }
    }

}

#Preview {
    EmailView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
