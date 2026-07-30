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

            logo

            VStack(spacing: 24) {
                Text("Pick a username")
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
                    isEnabled: !viewModel.username.isEmpty
                ) {
                    viewModel.advanceFromUsername()
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
        TextField("username", text: $viewModel.username)
            .font(Constants.Fonts.body)
            .padding()
            .background(Color.white)
            .cornerRadius(22)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .onChange(of: viewModel.username) { oldValue, newValue in
                if oldValue != newValue && newValue.count > oldValue.count {
                    viewModel.errorMessage = nil
                }
            }
    }

}

#Preview {
    UsernameView(viewModel: SignInView.ViewModel())
        .background(Constants.Colors.background)
}
