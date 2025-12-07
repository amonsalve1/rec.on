//
//  SwipePartyView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

struct SwipePartyView: View {
    @ObservedObject var viewModel: PartyViewModel
    let onComplete: (() -> Void)?
    
    @State private var i = 0
    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0
    @State private var showRes = false
    @State private var navWait = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: PartyViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    private let swipeThreshold: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Swipe swipe swipe!")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Spacer().frame(height: 8)

            if i < viewModel.candidates.count {
                let cand = viewModel.candidates[i]

                ZStack {
                    swipeCard(for: cand)
                }
                .frame(height: 260)
            } else {
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
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showRes = true
                                }
                            } else if success && viewModel.likedOptions.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navWait = true
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            if i < viewModel.candidates.count {
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
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Color(.systemGray6).ignoresSafeArea())
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

    private func swipeCard(for cand: PartyCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let imageUrl = cand.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.75, blue: 0.4),
                                            Color(red: 1.0, green: 0.55, blue: 0.35)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.75, blue: 0.4),
                                            Color(red: 1.0, green: 0.55, blue: 0.35)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.75, blue: 0.4),
                                    Color(red: 1.0, green: 0.55, blue: 0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(height: 160)
            .clipped()
            .cornerRadius(18)

            VStack(alignment: .leading, spacing: 6) {
                Text(cand.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                    Text(cand.address)
                }
                .font(.system(size: 13))
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
        guard i < viewModel.candidates.count else { return }

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
        }
    }
}
