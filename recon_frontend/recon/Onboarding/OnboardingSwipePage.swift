//
//  OnboardingSwipePage.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/30/2026.
//

import SwiftUI

/// The tutorial page: a real, draggable card. The user learns the mechanic
/// by performing it — a completed swipe (either direction) advances the flow.
struct OnboardingSwipePage: View {

    // MARK: - Properties

    /// Called once the tutorial card has been swiped away.
    let onSwiped: () -> Void

    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0
    @State private var flew = false

    // MARK: - Constants

    private let swipeThreshold: CGFloat = 80
    private let throwDistance: CGFloat = 600
    private let advanceDelay: TimeInterval = 0.45

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            title

            card
                .padding(.top, 28)

            actionButtons
                .padding(.top, 28)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var title: some View {
        VStack(spacing: 8) {
            Text("Swipe right on this card")
                .font(Constants.Fonts.title)
                .multilineTextAlignment(.center)

            Text("Right means yes. Left means no. That's the whole app.")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Constants.Colors.orangeLight,
                            Constants.Colors.orangePrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 150)
                .overlay(verdictBadge)

            VStack(alignment: .leading, spacing: 6) {
                Text("Thai Villa")
                    .font(Constants.Fonts.subheading)

                Text("Cozy · Spicy · Imaginary")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: 300)
        .offset(off)
        .rotationEffect(.degrees(Double(off.width / 20)))
        .opacity(op)
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !flew else { return }
                    off = value.translation
                }
                .onEnded { value in
                    handleDragEnd(translation: value.translation)
                }
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: off)
    }

    /// LIKE/NOPE stamp that fades in as the card tilts.
    @ViewBuilder
    private var verdictBadge: some View {
        if off.width != 0 {
            Text(off.width > 0 ? "LIKE" : "NOPE")
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Constants.Colors.ink.opacity(0.55))
                )
                .rotationEffect(.degrees(off.width > 0 ? -12 : 12))
                .opacity(min(Double(abs(off.width) / swipeThreshold), 1.0))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 48) {
            RoundBtn(
                systemName: "xmark",
                background: Constants.Colors.peach
            ) {
                fly(direction: -1)
            }

            RoundBtn(
                systemName: "checkmark",
                background: Constants.Colors.amber
            ) {
                fly(direction: 1)
            }
        }
    }

    // MARK: - Helpers

    private func handleDragEnd(translation: CGSize) {
        guard !flew else { return }

        if translation.width > swipeThreshold {
            fly(direction: 1)
        } else if translation.width < -swipeThreshold {
            fly(direction: -1)
        } else {
            withAnimation(.spring()) {
                off = .zero
            }
        }
    }

    /// Throws the card off screen and reports the tutorial as done.
    private func fly(direction: CGFloat) {
        guard !flew else { return }
        flew = true

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            off = CGSize(width: direction * throwDistance, height: 40)
            op = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + advanceDelay) {
            onSwiped()
        }
    }

}

#Preview {
    OnboardingSwipePage(onSwiped: {})
        .background(Constants.Colors.background)
}
