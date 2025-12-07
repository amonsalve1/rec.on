//
//  HomeSoloPartySection.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct HomeSoloPartySection: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 16) {
                Text("What do you reckon's next?")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                HStack(spacing: 16) {
                    NavigationLink {
                        SoloFlowView()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.orange)
                            Text("Solo")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }

                    NavigationLink {
                        PartySetupView()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.orange)
                            Text("Party")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, -16)
    }
}

