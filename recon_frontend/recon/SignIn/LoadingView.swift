//
//  LoadingView.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import SwiftUI

/// The interstitial shown while a register or login request is in flight.
struct LoadingView: View {

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            BrandWordmark(width: 148)

            ProgressView()
                .tint(Constants.Colors.orangePrimary)
                .padding(.top, 36)

            Text("Signing you in")
                .font(Constants.Fonts.heading)
                .foregroundColor(Constants.Colors.ink)
                .padding(.top, 24)

            Text("Just a sec")
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.inkSecondary)
                .padding(.top, 6)

            Spacer()
        }
    }

}

#Preview {
    LoadingView()
        .background(Constants.Colors.background)
}
