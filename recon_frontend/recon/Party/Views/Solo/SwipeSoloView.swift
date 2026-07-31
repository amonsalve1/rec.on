//
//  SwipeSoloView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

/// The solo swipe deck: like or pass each candidate, then hand the likes to the results flow.
struct SwipeSoloView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SoloFlowView.ViewModel

    @State private var i = 0
    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0
    @State private var isAnimating = false
    @State private var showRes = false

    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    init(viewModel: SoloFlowView.ViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    // MARK: - Constants

    private let swipeThreshold: CGFloat = 80

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Swipe swipe swipe!")
                .font(Constants.Fonts.title)

            Spacer().frame(height: 8)

            cardSection

            Spacer()

            actionButtons

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Constants.Colors.background.ignoresSafeArea())
        .navigationTitle("Solo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showRes) {
            SoloResultsFlowView(
                viewModel: viewModel,
                onComplete: onComplete
            )
        }
    }

    @ViewBuilder
    private var cardSection: some View {
        if i < viewModel.candidates.count {
            let cand = viewModel.candidates[i]

            ZStack {
                swipeCard(for: cand)
            }
            .frame(height: 260)
        } else {
            deckDoneState
        }
    }

    /// Shown once every card has been swiped. Deliberately button-driven, so
    /// navigating back from the results always lands somewhere that works.
    private var deckDoneState: some View {
        VStack(spacing: 16) {
            Spacer()

            FannedCards()

            Text("That's the deck!")
                .font(Constants.Fonts.title)

            Text(likedSummary)
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)

            Button {
                showRes = true
            } label: {
                Text("See your favorites")
                    .font(Constants.Fonts.bodySemibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Constants.Colors.orangeLight,
                                        Constants.Colors.orangePrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    private var likedSummary: String {
        let count = viewModel.liked.count
        switch count {
        case 0:
            return "Nothing caught your eye"
        case 1:
            return "You liked 1 option"
        default:
            return "You liked \(count) options"
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if i < viewModel.candidates.count {
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
    }

    // MARK: - Supporting

    /// The draggable card for the current candidate.
    private func swipeCard(for cand: PartyCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            cardImage(for: cand)

            cardDetails(for: cand)
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
                    guard !isAnimating else { return }
                    off = value.translation
                }
                .onEnded { value in
                    guard !isAnimating else { return }
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

    private func cardImage(for cand: PartyCandidate) -> some View {
        OptionArtwork(
            name: cand.name,
            imageUrl: cand.imageUrl,
            initialSize: 72
        )
        .frame(height: 160)
        .cornerRadius(18)
    }

    private func cardDetails(for cand: PartyCandidate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cand.name)
                .font(Constants.Fonts.subheading)

            if !cand.address.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(Constants.Fonts.caption)

                    Text(cand.address)
                }
                .font(Constants.Fonts.caption)
                .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(cand.tags.prefix(3), id: \.self) { tag in
                    Tag(text: tag)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - Helpers

    /// Records the swipe, animates the card off screen, then advances the deck.
    ///
    /// `isAnimating` gates re-entry: taps faster than the throw animation
    /// would otherwise stack, blanking the card for a frame and skipping
    /// past a candidate without recording a verdict for it.
    private func handleSwipe(liked: Bool) {
        guard !isAnimating, i < viewModel.candidates.count else { return }
        isAnimating = true

        let current = viewModel.candidates[i]
        let direction: CGFloat = liked ? 1 : -1

        viewModel.recordSwipe(for: current, liked: liked)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            off = CGSize(width: direction * 600, height: 40)
            op = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            off = .zero
            op = 1
            i += 1
            isAnimating = false
        }
    }

}

/// A round icon action button shown under the swipe deck.
struct RoundBtn: View {

    // MARK: - Properties

    let systemName: String
    let background: Color
    let action: () -> Void

    init(systemName: String, background: Color, action: @escaping () -> Void) {
        self.systemName = systemName
        self.background = background
        self.action = action
    }

    // MARK: - UI

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: 64, height: 64)

                Image(systemName: systemName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(.plain)
    }

}

/// A small orange pill label for a candidate tag.
struct Tag: View {

    // MARK: - Properties

    let text: String

    // MARK: - UI

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(Constants.Colors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Constants.Colors.accent.opacity(0.12))
            .cornerRadius(12)
    }

}

#Preview {
    NavigationStack {
        SwipeSoloView(viewModel: SoloFlowView.ViewModel())
    }
}
