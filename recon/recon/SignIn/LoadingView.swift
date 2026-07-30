//
//  LoadingView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

/// The interstitial shown while a register or login request is in flight.
struct LoadingView: View {

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            VStack(spacing: 12) {
                Text("Logging in...")
                    .font(Constants.Fonts.heading)
                    .foregroundColor(.black)
                    .padding(.top, 32)

                Text("Just a sec")
                    .font(Constants.Fonts.body)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }

}

#Preview {
    LoadingView()
        .background(Constants.Colors.background)
}
