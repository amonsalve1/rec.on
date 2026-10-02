//
//  BrandWordmark.swift
//  recon
//
//  Created by Anatoli Monsalve on 10/2/2026.
//

import SwiftUI

/// The script wordmark, for screens that sit on the warm canvas.
///
/// `RecOnLogo` is a white mark drawn for the orange splash, and it was being
/// placed on the cream canvas across the sign-in flow, where it rendered as a
/// pale ghost behind the content. `RecOnScriptLogo` carries its own orange
/// ramp, so on the canvas it reads as a logo rather than a watermark.
struct BrandWordmark: View {

    // MARK: - Properties

    /// Rendered width; the mark keeps its own aspect ratio.
    var width: CGFloat = 148

    // MARK: - UI

    var body: some View {
        Image("RecOnScriptLogo")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .accessibilityLabel("Rec.On")
    }

}

#Preview {
    VStack(spacing: 32) {
        BrandWordmark()

        BrandWordmark(width: 104)
    }
    .padding(32)
    .background(Constants.Colors.background)
}
