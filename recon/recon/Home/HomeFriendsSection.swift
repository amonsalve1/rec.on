//
//  HomeFriendsSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct HomeFriendsSection: View {
    let friends: [Friend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friends")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(friends) { friend in
                        VStack(spacing: 6) {
                            let imageUrl = getFriendImageUrl(for: friend.name)
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure(_), .empty:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.orange)
                                        .background(Color.orange.opacity(0.1))
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.orange)
                                        .background(Color.orange.opacity(0.1))
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())

                            Text(friend.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func getFriendImageUrl(for name: String) -> String {
        let seed = abs(name.hashValue) % 1000
        return "https://picsum.photos/seed/friend\(seed)/200/200"
    }
}
