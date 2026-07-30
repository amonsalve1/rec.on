//
//  ConfettiView.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import SwiftUI

/// A full-screen, non-interactive confetti overlay that rains randomized
/// pieces while active.
struct ConfettiView: View {

    // MARK: - Properties

    let isActive: Bool

    // MARK: - Constants

    private let pieceCount = 35

    private let colors: [Color] = [
        .orange, .yellow, .pink, .red, .mint, .blue
    ]

    // MARK: - UI

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieceCount, id: \.self) { i in
                    piece(at: i, in: geo)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Supporting

    private func piece(at i: Int, in geo: GeometryProxy) -> some View {
        let size = CGFloat(Int.random(in: 6...14))
        let x = CGFloat.random(in: 0...geo.size.width)
        let startY = CGFloat.random(in: -200 ... -20)
        let endY = geo.size.height + 60
        let rotation = Double.random(in: 0...360)
        let duration = Double.random(in: 2.0...3.5)
        let delay = Double.random(in: 0...0.6)

        return ConfettiPiece(
            color: colors[i % colors.count],
            size: size,
            startX: x,
            startY: startY,
            endY: endY,
            rotation: rotation,
            duration: duration,
            delay: delay,
            isActive: isActive
        )
    }

}

/// A single falling confetti rectangle that animates from its start position
/// off the bottom of the screen when activated.
struct ConfettiPiece: View {

    // MARK: - Properties

    @State private var animate = false

    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let rotation: Double
    let duration: Double
    let delay: Double
    let isActive: Bool

    // MARK: - UI

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size * 1.8)
            .cornerRadius(3)
            .position(x: startX, y: animate ? endY : startY)
            .rotationEffect(.degrees(animate ? rotation : 0))
            .opacity(animate ? 0 : 1)
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(
                        .linear(duration: duration)
                            .delay(delay)
                            .repeatForever(autoreverses: false)
                    ) {
                        animate = true
                    }
                }
            }
    }

}

#Preview {
    ConfettiView(isActive: true)
}
