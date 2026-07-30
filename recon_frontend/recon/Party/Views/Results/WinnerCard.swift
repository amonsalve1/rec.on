//
//  WinnerCard.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The large celebratory card showing the winning pick's photo, address, and tags.
struct WinnerCard: View {

    // MARK: - Properties

    let winner: PartyCandidate

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            photo

            details
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }

    private var photo: some View {
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
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(winner.name)
                .font(Constants.Fonts.subheading)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(Constants.Fonts.caption)

                Text(winner.address)
            }
            .font(Constants.Fonts.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(winner.tags.prefix(3), id: \.self) { tag in
                    Tag(text: tag)
                }
            }
        }
        .padding(14)
    }

}

#Preview {
    WinnerCard(
        winner: PartyCandidate(
            name: "Joe's Pizza",
            address: "7 Carmine St",
            tags: ["Pizza", "Casual"],
            imageName: "food1"
        )
    )
    .padding()
    .background(Constants.Colors.background)
}
