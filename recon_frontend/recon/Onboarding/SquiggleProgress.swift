//
//  SquiggleProgress.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/30/2026.
//

import SwiftUI

/// A hand-drawn wavy line used as the onboarding progress indicator: the
/// filled portion draws further along the squiggle as pages advance.
struct SquiggleProgress: View {

    // MARK: - Properties

    /// Fraction of the squiggle to fill, 0...1.
    let progress: CGFloat

    /// Stroke color of the filled portion.
    var tint: Color = Constants.Colors.orangePrimary

    /// Stroke color of the unfilled remainder.
    var track: Color = Constants.Colors.orangeLight.opacity(0.35)

    // MARK: - UI

    var body: some View {
        ZStack {
            SquiggleShape()
                .stroke(track, style: StrokeStyle(lineWidth: 3, lineCap: .round))

            SquiggleShape()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
    }

}

/// The wavy path itself: gentle alternating arcs across the width.
struct SquiggleShape: Shape {

    // MARK: - Helpers

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waves = 4
        let step = rect.width / CGFloat(waves)
        var x: CGFloat = 0
        var up = true

        path.move(to: CGPoint(x: 0, y: rect.midY))
        for _ in 0..<waves {
            let next = x + step
            path.addQuadCurve(
                to: CGPoint(x: next, y: rect.midY),
                control: CGPoint(x: x + step / 2, y: up ? rect.minY : rect.maxY)
            )
            x = next
            up.toggle()
        }
        return path
    }

}

#Preview {
    SquiggleProgress(progress: 0.66)
        .frame(width: 200, height: 14)
        .padding()
        .background(Constants.Colors.background)
}
