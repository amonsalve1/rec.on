//
//  HomeFriendsSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The horizontally scrolling row of friend avatars on the home screen.
struct HomeFriendsSection: View {

    // MARK: - Properties

    let friends: [Friend]

    // MARK: - Constants

    private let avatarSize: CGFloat = 80

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            title

            friendsRow
        }
    }

    private var title: some View {
        Text("Friends")
            .font(Constants.Fonts.sectionTitle)
    }

    private var friendsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(friends) { friend in
                    friendCell(for: friend)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Supporting

    private func friendCell(for friend: Friend) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: imageUrl(for: friend.name))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    avatarPlaceholder
                @unknown default:
                    avatarPlaceholder
                }
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())

            Text(friend.name)
                .font(Constants.Fonts.labelMedium)
                .foregroundColor(.primary)
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(Constants.Colors.accent)
            .background(Constants.Colors.accent.opacity(0.1))
    }

    // MARK: - Helpers

    /// Deterministic placeholder image URL for a friend until the backend
    /// serves real avatars.
    private func imageUrl(for name: String) -> String {
        let seed = abs(name.hashValue) % 1000
        return "https://picsum.photos/seed/friend\(seed)/200/200"
    }

}

#Preview {
    HomeFriendsSection(
        friends: [
            .init(name: "Mei Mei", imageName: "friend1"),
            .init(name: "Larry", imageName: "friend2")
        ]
    )
    .padding()
}
