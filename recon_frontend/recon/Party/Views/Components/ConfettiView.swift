//
//  ConfettiView.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import SwiftUI

/// A full-screen, non-interactive confetti burst.
///
/// Paper does four things that a straight downward tween does not: it drifts
/// sideways, tumbles continuously rather than settling on one angle, flips
/// edge-on so it seems to disappear and return, and reaches a terminal speed
/// after a short acceleration. Each piece animates those on separate
/// keyframe tracks, so no two fall alike.
struct ConfettiView: View {

    // MARK: - Properties

    let isActive: Bool

    @State private var pieces: [Piece] = []

    // MARK: - Constants

    private let pieceCount = 60

    // MARK: - UI

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    PieceView(piece: piece, fallHeight: geo.size.height + 120)
                }
            }
            .onChange(of: isActive, initial: true) { _, active in
                // built only when the burst fires, so the pieces are not
                // sitting off-screen mid-fall before the winner is revealed
                if active, pieces.isEmpty {
                    pieces = Self.makePieces(count: pieceCount, width: geo.size.width)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    /// Builds the pieces once. Randomising inside `body` would reshuffle
    /// every piece on each redraw and make the fall stutter.
    static func makePieces(count: Int, width: CGFloat) -> [Piece] {
        let palette: [Color] = [
            Constants.Colors.orangePrimary,
            Constants.Colors.orangeLight,
            Constants.Colors.amber,
            Constants.Colors.peach,
            .white,
            Constants.Colors.ink
        ]

        return (0..<count).map { index in
            let pieceWidth = CGFloat.random(in: 5...11)

            return Piece(
                id: index,
                color: palette.randomElement() ?? Constants.Colors.orangePrimary,
                size: CGSize(
                    width: pieceWidth,
                    height: pieceWidth * CGFloat.random(in: 1.2...2.2)
                ),
                isRound: Double.random(in: 0...1) < 0.25,
                startX: CGFloat.random(in: -20...(width + 20)),
                startY: CGFloat.random(in: -160 ... -30),
                sway: CGFloat.random(in: 18...70) * (Bool.random() ? 1 : -1),
                spin: Double.random(in: 360...1080) * (Bool.random() ? 1 : -1),
                flip: Double.random(in: 540...1440) * (Bool.random() ? 1 : -1),
                duration: Double.random(in: 2.4...4.2),
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
        let startX: CGFloat
        let startY: CGFloat
        /// Horizontal travel of the sway, in points.
        let sway: CGFloat
        /// Total in-plane rotation over the fall, in degrees.
        let spin: Double
        /// Total edge-on flip, in degrees.
        let flip: Double
        let duration: Double
        let delay: Double
    }

}

/// Animatable state for a single piece.
private struct PieceMotion {
    var y: CGFloat = 0
    var drift: CGFloat = 0
    var spin: Double = 0
    var flip: Double = 0
    var opacity: Double = 1
}

/// Drives one piece through its fall.
private struct PieceView: View {

    // MARK: - Properties

    let piece: ConfettiView.Piece
    let fallHeight: CGFloat

    // MARK: - UI

    var body: some View {
        KeyframeAnimator(initialValue: PieceMotion(y: piece.startY), repeating: false) { motion in
            shape
                .frame(width: piece.size.width, height: piece.size.height)
                .rotationEffect(.degrees(motion.spin))
                .rotation3DEffect(
                    .degrees(motion.flip),
                    axis: (x: 0.35, y: 1, z: 0.15),
                    perspective: 0.6
                )
                .opacity(motion.opacity)
                .position(x: piece.startX + motion.drift, y: motion.y)
        } keyframes: { _ in
            // hold each track through the stagger, then run the fall
            KeyframeTrack(\.y) {
                LinearKeyframe(piece.startY, duration: piece.delay)
                // short acceleration into terminal speed, not a constant slide
                CubicKeyframe(piece.startY + fallHeight * 0.22, duration: piece.duration * 0.3)
                LinearKeyframe(fallHeight, duration: piece.duration * 0.7)
            }

            KeyframeTrack(\.drift) {
                LinearKeyframe(0, duration: piece.delay)
                CubicKeyframe(piece.sway, duration: piece.duration * 0.32)
                CubicKeyframe(-piece.sway * 0.75, duration: piece.duration * 0.36)
                CubicKeyframe(piece.sway * 0.45, duration: piece.duration * 0.32)
            }

            KeyframeTrack(\.spin) {
                LinearKeyframe(0, duration: piece.delay)
                LinearKeyframe(piece.spin, duration: piece.duration)
            }

            KeyframeTrack(\.flip) {
                LinearKeyframe(0, duration: piece.delay)
                LinearKeyframe(piece.flip, duration: piece.duration)
            }

            KeyframeTrack(\.opacity) {
                LinearKeyframe(1, duration: piece.delay)
                // stays solid on the way down; only fades as it leaves
                LinearKeyframe(1, duration: piece.duration * 0.8)
                LinearKeyframe(0, duration: piece.duration * 0.2)
            }
        }
    }

    @ViewBuilder
    private var shape: some View {
        if piece.isRound {
            Circle().fill(piece.color)
        } else {
            RoundedRectangle(cornerRadius: 2).fill(piece.color)
        }
    }

}

#Preview {
    ZStack {
        Constants.Colors.background.ignoresSafeArea()

        ConfettiView(isActive: true)
    }
}
