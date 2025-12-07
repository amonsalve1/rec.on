//
//  RandomizingCard.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct RandCard: View {
    let candidate: PartyCandidate
    let center: Bool

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let imageUrl = candidate.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            Image(candidate.imageName)
                                .resizable()
                                .scaledToFill()
                        @unknown default:
                            Image(candidate.imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                } else {
                    Image(candidate.imageName)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: center ? 110 : 90)
            .clipped()
            .cornerRadius(14)
            .grayscale(center ? 0 : 1)
            .opacity(center ? 1 : 0.4)

            Text(candidate.name)
                .font(.system(size: center ? 16 : 14,
                              weight: .semibold,
                              design: .rounded))
                .lineLimit(1)
                .foregroundColor(.primary.opacity(center ? 1 : 0.6))
        }
        .padding(8)
        .background(Color.white.opacity(center ? 1 : 0.7))
        .cornerRadius(16)
        .shadow(color: .black.opacity(center ? 0.12 : 0.04),
                radius: center ? 8 : 3,
                x: 0,
                y: center ? 4 : 1)
        .scaleEffect(center ? 1.05 : 0.95)
        .animation(.easeInOut(duration: 0.15), value: center)
    }
}
