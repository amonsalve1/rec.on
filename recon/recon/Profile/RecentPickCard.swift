//
//  RecentPickCard.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct RecentPickCard: View {
    let pick: FinalPick
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let url = URL(string: pick.imageUrl), pick.imageUrl.hasPrefix("http") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color(.systemGray5)
                    }
                } else {
                    Image(pick.imageUrl.isEmpty ? "food1" : pick.imageUrl)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(pick.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                    Text(pick.address.isEmpty ? "Address not available" : pick.address)
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    ForEach(pick.tags.prefix(3), id: \.self) { tag in
                        Tag(text: tag)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
    }
}

