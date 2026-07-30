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
    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    init(viewModel: PartySetupView.ViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    // MARK: - Constants

    private let swipeThreshold: CGFloat = 80
    private let swipeOutDistance: CGFloat = 600
    private let swipeAdvanceDelay: Double = 0.3
    private let resultsNavigationDelay: Double = 0.3
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
            loadingState
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            Text("Loading your favorites…")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
        }
        .task {
            if !showRes && !navWait {
                viewModel.loadLikedOptions { success in
                    if success && !viewModel.likedOptions.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + resultsNavigationDelay) {
                            showRes = true
                        }
                    } else if success && viewModel.likedOptions.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + resultsNavigationDelay) {
                            navWait = true
                        }
                    }
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
                    off = value.translation
                }
                .onEnded { value in
                    handleSwipeEnd(translation: value.translation)
                }
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: off)
    }

    private func cardImage(for cand: PartyCandidate) -> some View {
        Group {
            if let imageUrl = cand.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_), .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: imageCornerRadius)
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
    }

    private func cardDetails(for cand: PartyCandidate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cand.name)
                .font(Constants.Fonts.subheading)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(Constants.Fonts.caption)
                Text(cand.address)
            }
            .font(Constants.Fonts.caption)
            .foregroundColor(.secondary)

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

    private func handleSwipe(liked: Bool) {
        guard i < viewModel.candidates.count else { return }

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
        }
    }

}

#Preview {
    NavigationStack {
        SwipePartyView(viewModel: PartySetupView.ViewModel())
    }
}
