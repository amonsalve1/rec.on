//
//  SwipePartyView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

/// The card-swiping step of a party: each member likes or passes on every
/// candidate, then moves on to pick a single favorite.
struct SwipePartyView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PartySetupView.ViewModel

    @State private var i = 0
    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0
    @State private var showRes = false
    @State private var navWait = false
    @State private var loadingLiked = false
    @State private var isAnimating = false
    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    init(
        viewModel: PartySetupView.ViewModel,
        startIndex: Int = 0,
        onComplete: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onComplete = onComplete
        _i = State(initialValue: startIndex)
    }

    // MARK: - Constants

    private let swipeThreshold: CGFloat = 80
    private let swipeOutDistance: CGFloat = 600
    private let swipeAdvanceDelay: Double = 0.3
    private let imageCornerRadius: CGFloat = 18

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Swipe swipe swipe!")
                .font(Constants.Fonts.title)

            Spacer().frame(height: 8)

            cardSection

            Spacer()

            if i < viewModel.candidates.count {
                actionButtons
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Constants.Colors.background.ignoresSafeArea())
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showRes) {
            FinalPickView(
                viewModel: viewModel,
                onComplete: onComplete
            )
        }
        .navigationDestination(isPresented: $navWait) {
            WaitingForOthersView(
                viewModel: viewModel,
                onComplete: onComplete
            )
        }
    }

    @ViewBuilder
    private var cardSection: some View {
        if i < viewModel.candidates.count {
            ZStack {
                swipeCard(for: viewModel.candidates[i])
            }
            .frame(height: 260)
        } else {
            deckDoneState
        }
    }

    /// Shown once every card has been swiped. Button-driven rather than a
    /// timed auto-advance: coming back from the pick screen lands here in a
    /// working state, and a failed liked-options fetch gets a retry for free.
    private var deckDoneState: some View {
        VStack(spacing: 16) {
            Spacer()

            FannedCards()

            Text("That's the deck!")
                .font(Constants.Fonts.title)

            Text("Time to pick your one favorite")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)

            Button {
                continueToPick()
            } label: {
                Group {
                    if loadingLiked {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .font(Constants.Fonts.bodySemibold)
                            .foregroundColor(.white)
                    }
                }
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
            .disabled(loadingLiked)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Helpers

    /// Fetches the liked options, then routes to the pick screen — or
    /// straight to the waiting room when nothing was liked.
    private func continueToPick() {
        guard !loadingLiked else { return }
        loadingLiked = true

        viewModel.loadLikedOptions { success in
            DispatchQueue.main.async {
                loadingLiked = false
                guard success else { return }

                if viewModel.likedOptions.isEmpty {
                    navWait = true
                } else {
                    showRes = true
                }
            }
        }
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

    // MARK: - Supporting

    private func swipeCard(for cand: PartyCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            cardImage(for: cand)
                .frame(height: 160)
                .clipped()
                .cornerRadius(imageCornerRadius)

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
                    handleSwipeEnd(translation: value.translation)
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
        .cornerRadius(imageCornerRadius)
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

    private func handleSwipeEnd(translation: CGSize) {
        let dx = translation.width
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

    /// `isAnimating` gates re-entry: taps faster than the throw animation
    /// would otherwise stack, blanking the card for a frame and skipping past
    /// a candidate without recording a verdict for it.
    private func handleSwipe(liked: Bool) {
        guard !isAnimating, i < viewModel.candidates.count else { return }
        isAnimating = true

        let current = viewModel.candidates[i]
        let direction: CGFloat = liked ? 1 : -1

        viewModel.recordSwipe(for: current, liked: liked)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            off = CGSize(width: direction * swipeOutDistance, height: 40)
            op = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + swipeAdvanceDelay) {
            off = .zero
            op = 1
            i += 1
            isAnimating = false
        }
    }

}

#Preview {
    NavigationStack {
        SwipePartyView(viewModel: PartySetupView.ViewModel())
    }
}
