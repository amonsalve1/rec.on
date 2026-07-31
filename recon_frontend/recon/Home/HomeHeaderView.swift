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
    var onJoinTap: (() -> Void)?

    // MARK: - Constants

    private let avatarSize: CGFloat = 52

    // MARK: - UI

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            greeting

            Spacer()

            if let onJoinTap {
                joinButton(action: onJoinTap)
            }

            avatarButton
        }
        .frame(maxWidth: .infinity)
    }

    /// Entry point for joining someone else's party by code.
    private func joinButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: "person.badge.plus")
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.ink)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.75))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(dayPart)
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Text("What's it gonna be\(userName.isEmpty ? "" : ", \(userName)")?")
                .font(Constants.Fonts.headingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Time-of-day line above the greeting — a small sign the screen is live
    /// rather than a static menu.
    private var dayPart: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        default:
            return "Evening"
        }
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
            // initial on brand, rather than a gray system silhouette
            Constants.Colors.peach
                .overlay(
                    Text(initial)
                        .font(Constants.Fonts.bodySemibold)
                        .foregroundColor(Constants.Colors.ink)
                )
        }
    }

    private var initial: String {
        guard let first = userName.trimmingCharacters(in: .whitespaces).first else {
            return "?"
        }
        return String(first).uppercased()
    }

    // MARK: - Helpers

    /// Loads the saved avatar from the documents directory, or `nil` if none
    /// has been saved yet.
    private func loadProfileImage() -> UIImage? {
        ProfileImageStore.load(from: profilePicturePath)
    }

}

#Preview {
    HomeHeaderView(
        userName: "Anatoli",
        profilePicturePath: "",
        onMenuTap: {}
    )
}
