//
//  SideMenuView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The slide-in side menu with the profile shortcut and settings entry.
struct SideMenuView: View {

    // MARK: - Properties

    let userName: String
    let profilePicturePath: String
    let onViewProfile: () -> Void
    let onSettings: () -> Void

    // MARK: - Constants

    private let avatarSize: CGFloat = 48
    private let glyphSize: CGFloat = 32

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            VStack(alignment: .leading, spacing: 24) {
                profileButton

                Divider().background(Color.black.opacity(0.2))

                menuItems

                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            glyph
        }
    }

    private var background: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [
                    Constants.Colors.menuGradientTop,
                    Constants.Colors.menuGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image("SideMenuBlob")
                .resizable()
                .scaledToFit()
                .frame(width: 230)
                .offset(x: 40, y: 40)
        }
    }

    private var profileButton: some View {
        Button {
            onViewProfile()
        } label: {
            HStack(spacing: 12) {
                avatar
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(userName)
                        .font(Constants.Fonts.subheading)

                    Text("View profile")
                        .font(Constants.Fonts.label)
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var avatar: some View {
        if let image = loadProfileImage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                onSettings()
            } label: {
                MenuRow(systemName: "gearshape", title: "Settings")
            }
            .buttonStyle(.plain)
        }
    }

    private var glyph: some View {
        Image("RecOnGlyph")
            .resizable()
            .scaledToFit()
            .frame(width: glyphSize, height: glyphSize)
            .padding(.bottom, 24)
    }

    // MARK: - Helpers

    /// Loads the saved avatar from the documents directory, or `nil` if none
    /// has been saved yet.
    private func loadProfileImage() -> UIImage? {
        guard !profilePicturePath.isEmpty else { return nil }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent(profilePicturePath)

        guard let imageData = try? Data(contentsOf: imageURL) else { return nil }

        return UIImage(data: imageData)
    }

}

#Preview {
    SideMenuView(
        userName: "User",
        profilePicturePath: "",
        onViewProfile: {},
        onSettings: {}
    )
    .frame(width: 300)
}
