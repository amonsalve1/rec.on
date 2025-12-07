//
//  PickCard.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct PickCard: View {
    let candidate: PartyCandidate

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlStr = candidate.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Image(candidate.imageName).resizable().scaledToFill()
                        }
                    }
                } else {
                    Image(candidate.imageName).resizable().scaledToFill()
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(12)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 12))
                    Text(candidate.address)
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)

                if !candidate.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(candidate.tags.prefix(3)), id: \.self) { tag in
                            Tag(text: tag)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}
