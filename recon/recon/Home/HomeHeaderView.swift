//
//  HomeHeaderView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import UIKit

/// The home screen greeting header with the profile avatar that opens the
/// side menu.
struct HomeHeaderView: View {

    // MARK: - Properties

    let userName: String
    let profilePicturePath: String
    let onMenuTap: () -> Void

    // MARK: - Constants

    private let avatarSize: CGFloat = 52

    // MARK: - UI

    var body: some View {
        HStack {
            greeting

            Spacer()

            avatarButton
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }

    private var greeting: some View {
        Text("Hi \(userName.isEmpty ? "User" : userName)!")
            .font(Constants.Fonts.display)
            .padding(.vertical, Constants.Padding.screenHorizontal)
            .padding(.horizontal, Constants.Padding.screenHorizontal)
    }

    private var avatarButton: some View {
        Button {
            onMenuTap()
        } label: {
            avatar
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
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
                .foregroundColor(.gray)
        }
    }

    // MARK: - Helpers

    /// Loads the saved avatar from the documents directory, or `nil` if none
    /// has been saved yet.
    private func loadProfileImage() -> UIImage? {
        guard !profilePicturePath.isEmpty else { return nil }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(profilePicturePath)

        guard
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }

}

#Preview {
    HomeHeaderView(
        userName: "Anatoli",
        profilePicturePath: "",
        onMenuTap: {}
    )
}
