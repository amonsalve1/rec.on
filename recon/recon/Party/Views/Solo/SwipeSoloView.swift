//
//  SwipeSoloView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

struct SwipeSoloView: View {
    @ObservedObject var viewModel: SoloViewModel
    let onComplete: (() -> Void)?
    
    @State private var i = 0
    @State private var off: CGSize = .zero
    @State private var op: Double = 1.0
    @State private var showRes = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: SoloViewModel, onComplete: (() -> Void)? = nil) {
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
                    if !showRes {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showRes = true
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
        .navigationTitle("Solo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showRes) {
            SoloResultsFlowView(
                candidates: viewModel.liked,
                onComplete: {
                    showRes = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onComplete?()
                    }
                }
            )
        }
    }
    
    private func swipeCard(for cand: PartyCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let imageUrl = cand.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            Image(cand.imageName)
                                .resizable()
                                .scaledToFill()
                        @unknown default:
                            Image(cand.imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                } else {
                    Image(cand.imageName)
                        .resizable()
                        .scaledToFill()
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

struct RoundBtn: View {
    let systemName: String
    let background: Color
    let action: () -> Void

    init(systemName: String, background: Color, action: @escaping () -> Void) {
        self.systemName = systemName
        self.background = background
        self.action = action
    }

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

struct Tag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(12)
    }
}
