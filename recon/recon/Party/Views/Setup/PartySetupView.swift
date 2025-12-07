//
//  PartySetupView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI

struct PartySetupView: View {
    @StateObject var viewModel = PartyViewModel()
    let onComplete: (() -> Void)?
    
    @State private var pg = 0
    @State private var start = false
    @State private var err = false
    @State private var navSwipe = false
    @State private var topic: String? = nil
    @Environment(\.dismiss) var dismiss
    
    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
                TabView(selection: $pg) {
                    PartyTopicPage { topicKey in
                        topic = topicKey
                        startParty(with: topicKey)
                    }
                    .tag(0)
                    
                    PartyInvitePage(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(pg == 0 ? .primary : .secondary.opacity(0.4))
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(pg == 1 ? .primary : .secondary.opacity(0.4))
                }
                .padding(.vertical, 10)

                Button(action: bottomButtonTapped) {
                    Text(buttonText)
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
                .disabled((start && pg == 0) || (pg == 0 && topic == nil))
                .opacity((pg == 0 && topic == nil) ? 0.5 : 1.0)
                .padding(.bottom, 24)
            }
            .navigationTitle("Party")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $err) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .navigationDestination(isPresented: $navSwipe) {
                SwipePartyView(
                    viewModel: viewModel,
                    onComplete: {
                        dismiss()
                        onComplete?()
                    }
                )
            }
    }

    var buttonText: String {
        if pg == 0 {
            return "Next"
        } else {
            return start ? "Starting…" : "Start swiping"
        }
    }

    func bottomButtonTapped() {
        if pg == 0 {
            withAnimation {
                pg = 1
            }
        } else {
            guard viewModel.session != nil else { return }
            navSwipe = true
        }
    }

    func startParty(with topicKey: String) {
        start = true
        viewModel.startParty(topic: topicKey) { success in
            DispatchQueue.main.async {
                start = false
                if !success {
                    err = true
                } else {
                    withAnimation {
                        pg = 1
                    }
                }
            }
        }
    }
}
