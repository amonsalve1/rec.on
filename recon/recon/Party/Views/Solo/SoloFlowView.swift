//
//  SoloFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

struct SoloFlowView: View {
    @StateObject private var viewModel = SoloViewModel()
    
    @State private var pg = 0
    @State private var start = false
    @State private var err = false
    @State private var navSwipe = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pg) {
                PartyTopicPage { topicKey in
                    startSolo(with: topicKey)
                }
                .tag(0)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            HStack(spacing: 8) {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(pg == 0 ? .primary : .secondary.opacity(0.4))
            }
            .padding(.vertical, 10)
            
            Button(action: bottomButtonTapped) {
                Text(start ? "Starting…" : "Start swiping")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                Color(red: 1.0, green: 0.55, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
                    .padding(.horizontal, 32)
            }
            .disabled(start)
            .padding(.bottom, 24)
        }
        .alert("Error", isPresented: $err) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .navigationDestination(isPresented: $navSwipe) {
            SwipeSoloView(
                viewModel: viewModel,
                onComplete: {
                    navSwipe = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            )
        }
        .navigationTitle("Solo")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func bottomButtonTapped() {
    }
    
    private func startSolo(with topicKey: String) {
        start = true
        viewModel.startSolo(topic: topicKey) { success in
            DispatchQueue.main.async {
                start = false
                if !success {
                    err = true
                } else {
                    navSwipe = true
                }
            }
        }
    }
}
