//
//  CanvasBackground.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// The app's canvas: warm paper with a soft brand wash bleeding down from
/// the top, so a screen reads as a designed surface rather than the system's
/// default gray.
struct CanvasBackground: View {

    // MARK: - Properties

    /// How far down the wash reaches.
    var washHeight: CGFloat = 300

    /// How strong the wash is at its darkest point.
    var intensity: Double = 0.38

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .top) {
            Constants.Colors.background

            LinearGradient(
                colors: [
                    Constants.Colors.canvasWash.opacity(intensity),
                    Constants.Colors.canvasWash.opacity(intensity * 0.35),
                    Constants.Colors.background.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: washHeight)
        }
        .ignoresSafeArea()
    }

}

#Preview {
    ZStack {
        CanvasBackground()

        VStack {
            Text("What's it gonna be?")
                .font(Constants.Fonts.headingMedium)
                .padding(.top, 60)

            Spacer()
        }
    }
}
