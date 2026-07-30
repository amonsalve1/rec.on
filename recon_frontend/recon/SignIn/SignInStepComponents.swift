//
//  SignInStepComponents.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import SwiftUI

/// The circular back chevron shown at the top of each wizard step.
struct SignInBackButton: View {

    // MARK: - Properties

    let action: () -> Void

    // MARK: - UI

    var body: some View {
        HStack {
            Button {
                action()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Constants.Fonts.buttonLabel)
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Constants.Colors.accent)
                    .clipShape(Circle())
            }
            .padding(.leading, 24)
            .padding(.top, Constants.Padding.screenHorizontal)

            Spacer()
        }
    }

}

/// The row of progress dots at the bottom of the wizard.
struct SignInStepDots: View {

    // MARK: - Properties

    let total: Int

    /// Highest dot index to fill; pass -1 to render all dots inactive.
    let activeThrough: Int

    // MARK: - UI

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(
                        index <= activeThrough
                            ? Constants.Colors.ink
                            : Color.gray.opacity(0.3)
                    )
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.bottom, 50)
    }

}

/// The white full-width confirm button used by each wizard step, greyed out
/// until the step's field has content.
struct SignInNextButton: View {

    // MARK: - Properties

    let title: String
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(Constants.Fonts.buttonLabel)
                .foregroundColor(isEnabled ? .black : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.white : Color.gray.opacity(0.2))
                .cornerRadius(22)
        }
        .disabled(!isEnabled)
    }

}

#Preview {
    VStack(spacing: 24) {
        SignInBackButton(action: {})

        SignInStepDots(total: 3, activeThrough: 1)

        SignInNextButton(
            title: "Next",
            isEnabled: true,
            action: {}
        )
        .padding(.horizontal, 32)
    }
}
