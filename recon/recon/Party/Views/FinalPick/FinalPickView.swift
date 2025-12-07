//
//  FinalPickView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

struct FinalPickView: View {
    @ObservedObject var viewModel: PartyViewModel
    let onComplete: (() -> Void)?
    
    @State private var sel: PartyCandidate?
    @State private var sub = false
    @State private var navWait = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: PartyViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your pick")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text("Choose ONE option to enter the pool")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
            
            if viewModel.likedOptions.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("No favorites selected")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("You didn't like any options. You'll be skipped in the final pick.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
                let pick = sel ?? viewModel.likedOptions.first
                
                if let pick = pick {
                    VStack(spacing: 16) {
                        Text("This will be your ONE pick in the pool:")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        SelectablePickCard(
                            candidate: pick,
                            selected: true
                        ) {
                            if viewModel.likedOptions.count > 1 {
                                if let i = viewModel.likedOptions.firstIndex(where: { $0.id == pick.id }) {
                                    let next = (i + 1) % viewModel.likedOptions.count
                                    sel = viewModel.likedOptions[next]
                                }
                            }
                        }
                        
                        if viewModel.likedOptions.count > 1 {
                            Text("Tap to switch to another option")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: submitPick) {
                Text(sub ? "Submitting…" : "Confirm Pick")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: sel != nil ? [
                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                Color(red: 1.0, green: 0.55, blue: 0.35)
                            ] : [
                                Color.gray,
                                Color.gray
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
            }
            .disabled((sel == nil && !viewModel.likedOptions.isEmpty) || sub || viewModel.hasSubmittedFinalPick)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle("Final Pick")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sel == nil && !viewModel.likedOptions.isEmpty {
                sel = viewModel.likedOptions.first
            }
        }
        .navigationDestination(isPresented: $navWait) {
            WaitingForOthersView(
                viewModel: viewModel,
                onComplete: onComplete
            )
        }
    }
    
    private func submitPick() {
        guard !viewModel.hasSubmittedFinalPick else { return }
        
        if viewModel.likedOptions.isEmpty {
            navWait = true
            return
        }
        
        let pick = sel ?? viewModel.likedOptions.first
        guard let pick = pick else { return }
        
        sub = true
        
        viewModel.submitFinalPick(candidate: pick) { success in
            sub = false
            if success {
                navWait = true
            }
        }
    }
}

struct SelectablePickCard: View {
    let candidate: PartyCandidate
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Group {
                    if let imageUrl = candidate.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure(_), .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                                Color(red: 1.0, green: 0.55, blue: 0.35)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            @unknown default:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                                Color(red: 1.0, green: 0.55, blue: 0.35)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.75, blue: 0.4),
                                        Color(red: 1.0, green: 0.55, blue: 0.35)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if !candidate.address.isEmpty {
                        Text(candidate.address)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.35))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selected ? Color(red: 1.0, green: 0.55, blue: 0.35) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
