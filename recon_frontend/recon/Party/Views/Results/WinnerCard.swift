//
//  WinnerCard.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct WinnerCard: View {
    let winner: PartyCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let imageUrl = winner.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            Image(winner.imageName)
                                .resizable()
                                .scaledToFill()
                        @unknown default:
                            Image(winner.imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                } else {
                    Image(winner.imageName)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 230)
            .clipped()
            .cornerRadius(18)

            VStack(alignment: .leading, spacing: 6) {
                Text(winner.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                    Text(winner.address)
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ForEach(winner.tags.prefix(3), id: \.self) { tag in
                        Tag(text: tag)
                    }
                }
            }
            .padding(14)
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}
