//
//  PrimaryButton.swift
//  recon
//
//  Created by Anatoli Monsalve on 10/2/2026.
//

import SwiftUI

/// The app's one call to action: a full-width pill carrying the brand ramp.
///
/// Every primary action goes through this view, so the gradient is defined
/// once and a button can never end up white-on-cream and look disabled.
struct PrimaryButton: View {

    // MARK: - Properties

    let title: String

    /// Whether the action can be taken. A disabled button keeps its shape and
    /// loses its fill, so the layout does not move when a field is completed.
    var isEnabled: Bool = true

    /// Swaps the label for a spinner while a request is in flight.
    var isLoading: Bool = false

    let action: () -> Void

    // MARK: - UI

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .font(Constants.Fonts.bodySemibold)
            .foregroundColor(isEnabled ? .white : Constants.Colors.controlDisabledInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Constants.Radius.control)
                    .fill(
                        isEnabled
                            ? AnyShapeStyle(Constants.Gradients.brand)
                            : AnyShapeStyle(Constants.Colors.controlDisabled)
                    )
            )
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeOut(duration: 0.18), value: isEnabled)
    }

}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", action: {})

        PrimaryButton(title: "Continue", isEnabled: false, action: {})

        PrimaryButton(title: "Continue", isLoading: true, action: {})
    }
    .padding(32)
    .background(Constants.Colors.background)
}
