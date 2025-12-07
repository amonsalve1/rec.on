//
//  HomePreviousPicksSection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct HomePreviousPicksSection: View {
    let recentPicks: [FinalPick]
    let onSeeAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your previous picks")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                Spacer()

                Button {
                    onSeeAll()
                } label: {
                    Capsule()
                        .fill(Color.orange)
                        .frame(width: 80, height: 32)
                        .overlay(
                            Text("See all")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    if recentPicks.isEmpty {
                        Text("No recent picks yet")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(recentPicks) { pick in
                            VStack(spacing: 8) {
                                Group {
                                    if let url = URL(string: pick.imageUrl), pick.imageUrl.hasPrefix("http") {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure(_), .empty:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                                                Color(red: 1.0, green: 0.55, blue: 0.35)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            @unknown default:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                                                Color(red: 1.0, green: 0.55, blue: 0.35)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            }
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 1.0, green: 0.75, blue: 0.4),
                                                        Color(red: 1.0, green: 0.55, blue: 0.35)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                }
                                .frame(width: 110, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Text(pick.name)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(width: 110, alignment: .center)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

