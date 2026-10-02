//
//  SquiggleShape.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

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
