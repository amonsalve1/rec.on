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

            logo

            VStack(spacing: 24) {
                Text("What's your password?")
                    .font(Constants.Fonts.heading)
                    .foregroundColor(Constants.Colors.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                field

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Constants.Fonts.bodySmall)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                SignInNextButton(
                    title: "Confirm",
                    isEnabled: !viewModel.password.isEmpty
                ) {
                    viewModel.submitPassword()
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var logo: some View {
        Image("RecOnLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
    }

    private var field: some View {
        SecureField("Password", text: $viewModel.password)
            .font(Constants.Fonts.body)
            .padding()
            .background(Color.white)
            .cornerRadius(22)
            .onChange(of: viewModel.password) { _, _ in
                viewModel.errorMessage = nil
            }
    }

}

#Preview {
    PasswordView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
