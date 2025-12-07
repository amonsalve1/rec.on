//
//  PartySwipeIntroPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI

struct PartySwipeIntroPage: View {
    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0

    private let swipeThreshold: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Swipe swipe swipe!")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Spacer().frame(height: 8)

            ZStack {
                swipeCard
            }
            .frame(height: 260)

            Spacer()

            HStack {
                Spacer()

                RoundBtn(
                    systemName: "xmark",
                    background: Color(red: 1.0, green: 0.7, blue: 0.6)
                ) {
                    handleSwipe(liked: false)
                }

                Spacer()

                RoundBtn(
                    systemName: "checkmark",
                    background: Color(red: 0.99, green: 0.77, blue: 0.45)
                ) {
                    handleSwipe(liked: true)
                }

                Spacer()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private var swipeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("food1")
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .clipped()
                .cornerRadius(18)

            VStack(alignment: .leading, spacing: 6) {
                Text("Xi'an Street Food")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                    Text("120 Dryden Rd, Ithaca, NY 14850")
                }
                .font(.system(size: 13))
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
