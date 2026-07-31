//
//  HomeJoinSheet.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// Where you enter a code a friend shared. Joining is invite-only, and this
/// is the one place to do it — previously the field lived inside your own
/// party setup, so joining a friend meant first creating a party you did not
/// want.
struct HomeJoinSheet: View {

    // MARK: - Properties

    let onJoin: (String, @escaping (Bool) -> Void) -> Void

    @State private var code = ""
    @State private var joining = false
    @State private var failed = false

    @Environment(\.dismiss) private var dismiss
    @FocusState private var codeFocused: Bool

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Join a party")
                .font(Constants.Fonts.heading)
                .padding(.top, 28)

            Text("Ask whoever started it for the code.")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)

            field

            if failed {
                Text("That code didn't work. It may have expired or the party already started.")
                    .font(Constants.Fonts.label)
                    .foregroundColor(Constants.Colors.danger)
            }

            joinButton

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            codeFocused = true
        }
    }

    private var field: some View {
        TextField("ABCDE-FGHIJ", text: $code)
            .font(Constants.Fonts.subheading)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .focused($codeFocused)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .onChange(of: code) { _, _ in
                failed = false
            }
    }

    private var joinButton: some View {
        Button {
            submit()
        } label: {
            Group {
                if joining {
                    ProgressView().tint(.white)
                } else {
                    Text("Join")
                        .font(Constants.Fonts.bodySemibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        code.isEmpty
                            ? AnyShapeStyle(Color.gray.opacity(0.3))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Constants.Colors.orangeLight,
                                        Constants.Colors.orangePrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            )
        }
        .disabled(code.isEmpty || joining)
    }

    // MARK: - Helpers

    private func submit() {
        guard !code.isEmpty, !joining else { return }
        joining = true

        onJoin(code) { success in
            joining = false
            if success {
                dismiss()
            } else {
                failed = true
            }
        }
    }

}

#Preview {
    HomeJoinSheet(onJoin: { _, done in done(false) })
        .background(Constants.Colors.background)
}
