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

            logo

            VStack(spacing: 24) {
                Text("What's your email?")
                    .font(Constants.Fonts.heading)
                    .foregroundColor(.black)
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
                    title: "Next",
                    isEnabled: !viewModel.email.isEmpty
                ) {
                    viewModel.advanceFromEmail()
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
        TextField("email@example.com", text: $viewModel.email)
            .font(Constants.Fonts.body)
            .padding()
            .background(Color.white)
            .cornerRadius(22)
            .autocapitalization(.none)
            .keyboardType(.emailAddress)
            .onChange(of: viewModel.email) { _, _ in
                viewModel.errorMessage = nil
            }
    }

}

#Preview {
    EmailView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
