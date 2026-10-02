//
//  ConfettiView.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import SwiftUI

/// A full-screen, non-interactive confetti burst.
///
/// Paper does four things a straight downward tween does not: it drifts
/// sideways, tumbles as it goes, turns edge-on so it seems to vanish and come
/// back, and reaches a terminal speed after a short acceleration. Every piece
/// is drawn from elapsed time rather than animated, so a redraw of the page
/// behind it — the winner's photo finishing its download, say — cannot leave
/// the fall stranded half way down.
struct ConfettiView: View {

    // MARK: - Properties

    let isActive: Bool

    @State private var pieces: [Piece] = []
    @State private var start = Date.distantFuture
    @State private var finished = false

    // MARK: - Constants

    private let pieceCount = 60

    // MARK: - UI

    var body: some View {
        GeometryReader { geo in
            if !finished {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(start)

                    ZStack {
                        ForEach(pieces) { piece in
                            view(for: piece, at: elapsed, in: geo.size)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive, initial: true) { _, active in
            // built only when the burst fires, so the pieces are not sitting
            // off-screen mid-fall before the winner is revealed
            guard active, pieces.isEmpty else { return }

            pieces = Self.makePieces(count: pieceCount)
            start = .now

            let lifetime = pieces.map { $0.delay + $0.duration }.max() ?? 0
            Task {
                try? await Task.sleep(for: .seconds(lifetime + 0.2))
                finished = true
            }
        }
    }

    // MARK: - Drawing

    /// One piece, placed from elapsed time rather than animated towards a
    /// target, so there is no in-flight animation for a redraw to strand.
    @ViewBuilder
    private func view(for piece: Piece, at elapsed: TimeInterval, in size: CGSize) -> some View {
        let progress = (elapsed - piece.delay) / piece.duration

        if progress > 0, progress < 1 {
            let fallHeight = size.height + 140
            let startY = -piece.startHeight
            let x = piece.startX * size.width + piece.sway * sin(
                piece.swayTurns * 2 * .pi * progress + piece.swayPhase
            )
            let y = startY + (fallHeight - startY) * Self.fallCurve(progress)
            // an edge-on flip reads as the piece narrowing to nothing and
            // opening back up, which is its width scaled by the cosine of
            // the turn
            let flip = abs(cos(piece.flipTurns * 2 * .pi * progress))

            shape(for: piece)
                .frame(width: piece.size.width, height: piece.size.height)
                .rotationEffect(.degrees(piece.spinTurns * 360 * progress))
                .scaleEffect(x: max(flip, 0.05), y: 1)
                .opacity(progress < 0.8 ? 1 : (1 - progress) / 0.2)
                .position(x: x, y: y)
        }
    }

    @ViewBuilder
    private func shape(for piece: Piece) -> some View {
        if piece.isRound {
            Circle().fill(piece.color)
        } else {
            RoundedRectangle(cornerRadius: 2).fill(piece.color)
        }
    }

    // MARK: - Helpers

    /// Fraction of the fall covered by `progress`: a short acceleration, then
    /// the constant terminal speed that paper actually settles into.
    private static func fallCurve(_ progress: Double) -> Double {
        let ramp = 0.3
        let travelled = progress < ramp
            ? 0.5 * progress * progress / ramp
            : 0.5 * ramp + (progress - ramp)
        return travelled / (0.5 * ramp + (1 - ramp))
    }

    /// Builds the pieces once. Randomising per frame would reshuffle every
    /// piece on each redraw and turn the fall into static.
    static func makePieces(count: Int) -> [Piece] {
        let palette: [Color] = [
            Constants.Colors.orangePrimary,
            Constants.Colors.orangeLight,
            Constants.Colors.amber,
            Constants.Colors.peach,
            .white,
            Constants.Colors.ink
        ]

        return (0..<count).map { index in
            let width = CGFloat.random(in: 5...11)

            return Piece(
                id: index,
                color: palette.randomElement() ?? Constants.Colors.orangePrimary,
                size: CGSize(width: width, height: width * CGFloat.random(in: 1.2...2.2)),
                isRound: Double.random(in: 0...1) < 0.25,
                startX: Double.random(in: -0.05...1.05),
                startHeight: CGFloat.random(in: 30...200),
                sway: CGFloat.random(in: 18...70) * (Bool.random() ? 1 : -1),
                swayTurns: Double.random(in: 0.75...1.75),
                swayPhase: Double.random(in: 0...(2 * .pi)),
                spinTurns: Double.random(in: 1...3) * (Bool.random() ? 1 : -1),
                flipTurns: Double.random(in: 1.5...4),
                duration: Double.random(in: 2.6...4.4),
                delay: Double.random(in: 0...0.9)
            )
        }
    }

    /// One piece of paper.
    struct Piece: Identifiable {
        let id: Int
        let color: Color
        let size: CGSize
        let isRound: Bool
        /// Horizontal start as a fraction of the width, so the burst does not
        /// depend on the size the view happened to be built at.
        let startX: Double
        /// How far above the top edge the piece begins.
        let startHeight: CGFloat
        /// Horizontal travel of the sway, in points.
        let sway: CGFloat
        let swayTurns: Double
        let swayPhase: Double
        /// In-plane rotations over the fall.
        let spinTurns: Double
        /// Edge-on flips over the fall.
        let flipTurns: Double
        let duration: Double
        let delay: Double
    }

}

#Preview {
    ZStack {
        Constants.Colors.background.ignoresSafeArea()

        ConfettiView(isActive: true)
    }
}
