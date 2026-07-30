//
//  PicksListPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct PicksListPage: View {
    let candidates: [PartyCandidate]
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pool of picks").font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("One pick from each person")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(candidates.count) picks")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(candidates) { cand in
                        PickCard(candidate: cand)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()

            Button {
                onConfirm()
            } label: {
                Text("Confirm")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.75, blue: 0.4), Color(red: 1.0, green: 0.55, blue: 0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}
