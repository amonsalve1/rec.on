//
//  SignInStepComponents.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import SwiftUI

/// The back control at the top of each wizard step.
///
/// This was a solid disc of system orange with a black chevron, which read as a
/// primary action sitting above the actual one. Navigation is chrome, so it is
/// drawn as chrome: the brand colour on a tint, at the weight of a back button.
struct SignInBackButton: View {

    // MARK: - Properties

    let action: () -> Void

    // MARK: - UI

    var body: some View {
        HStack {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(Constants.Fonts.buttonLabel)
                    .foregroundColor(Constants.Colors.orangePrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Constants.Colors.orangePrimary.opacity(0.12))
                    )
            }
            .accessibilityLabel("Back")

            Spacer()
        }
        .padding(.horizontal, Constants.Padding.screenHorizontal)
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
                Capsule()
                    .fill(
                        index <= activeThrough
                            ? Constants.Colors.orangePrimary
                            : Constants.Colors.orangePrimary.opacity(0.22)
                    )
                    /// The reached step widens rather than only darkening, so
                    /// progress is legible without relying on colour alone.
                    .frame(width: index == activeThrough ? 20 : 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: activeThrough)
    }

}

/// A placeholder in the app's secondary ink.
///
/// Passed as a field's `prompt:` rather than its title, because a bare title
/// placeholder is drawn by the system in the app accent, which reads as blue
/// text on a warm orange screen.
func signInPrompt(_ text: String) -> Text {
    Text(text)
        .foregroundColor(Constants.Colors.inkSecondary)
}

/// A text field styled for the warm canvas.
///
/// A hairline border, because a white field on cream reads as the same
/// surface as the white button beneath it, and field and action blur into one
/// element.
struct SignInField<Field: View>: View {

    // MARK: - Properties

    @ViewBuilder let content: () -> Field

    // MARK: - UI

    var body: some View {
        content()
            .font(Constants.Fonts.body)
            .foregroundColor(Constants.Colors.ink)
            .tint(Constants.Colors.orangePrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: Constants.Radius.control)
                    .fill(Constants.Colors.fieldSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Radius.control)
                    .stroke(Constants.Colors.fieldStroke, lineWidth: 1)
            )
    }

}

#Preview {
    VStack(spacing: 24) {
        SignInBackButton(action: {})

        SignInStepDots(total: 3, activeThrough: 1)

        SignInField {
            TextField("", text: .constant(""), prompt: signInPrompt("email@example.com"))
        }

        PrimaryButton(title: "Next", action: {})
    }
    .padding(.horizontal, 32)
    .background(Constants.Colors.background)
}
