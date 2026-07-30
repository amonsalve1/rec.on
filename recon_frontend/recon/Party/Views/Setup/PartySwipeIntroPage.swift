//
//  PartySwipeIntroPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI

/// An intro page with a practice swipe card, so users can try the swipe
/// gesture and the like/dislike buttons before a real session.
struct PartySwipeIntroPage: View {

    // MARK: - Properties

    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0

    // MARK: - Constants

    private let swipeThreshold: CGFloat = 80

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            title

            Spacer().frame(height: 8)

            cardArea

            Spacer()

            actionButtons

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private var title: some View {
        Text("Swipe swipe swipe!")
            .font(Constants.Fonts.title)
    }

    private var cardArea: some View {
        ZStack {
            swipeCard
        }
        .frame(height: 260)
    }

    private var swipeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardImage

            cardDetails
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .offset(off)
        .rotationEffect(.degrees(Double(off.width / 20)))
        .opacity(op)
        .gesture(
            DragGesture()
                .onChanged { value in
                    off = value.translation
                }
                .onEnded { value in
                    let dx = value.translation.width
                    if dx > swipeThreshold {
                        handleSwipe(liked: true)
                    } else if dx < -swipeThreshold {
                        handleSwipe(liked: false)
                    } else {
                        withAnimation(.spring()) {
                            off = .zero
                        }
                    }
                }
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: off)
    }

    private var cardImage: some View {
        Image("food1")
            .resizable()
            .scaledToFill()
            .frame(height: 160)
            .clipped()
            .cornerRadius(18)
    }

    private var cardDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Xi'an Street Food")
                .font(Constants.Fonts.subheading)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(Constants.Fonts.caption)

                Text("120 Dryden Rd, Ithaca, NY 14850")
            }
            .font(Constants.Fonts.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 6) {
                Tag(text: "College Town")

                Tag(text: "Chinese")
            }

            Text("Casual joint turning out fresh, authentic Xi'an fare such as hand-pulled noodles, spiced-meat buns.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private var actionButtons: some View {
        HStack {
            Spacer()

            RoundBtn(
                systemName: "xmark",
                background: Constants.Colors.peach
            ) {
                handleSwipe(liked: false)
            }

            Spacer()

            RoundBtn(
                systemName: "checkmark",
                background: Constants.Colors.amber
            ) {
                handleSwipe(liked: true)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func handleSwipe(liked: Bool) {
        let direction: CGFloat = liked ? 1 : -1

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            off = CGSize(width: direction * 600, height: 40)
            op = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                off = .zero
                op = 1
            }
        }
    }

}

#Preview {
    PartySwipeIntroPage()
}
