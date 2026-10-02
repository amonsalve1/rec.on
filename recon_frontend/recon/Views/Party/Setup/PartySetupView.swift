//
//  PartySetupView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI

/// The two-page party setup flow: pick a topic, then invite friends before
/// heading into the group swipe session.
struct PartySetupView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss

    @StateObject var viewModel = ViewModel()

    @State private var pg = 0
    @State private var start = false
    @State private var err = false
    @State private var navSwipe = false
    @State private var topic: String? = nil

    let onComplete: (() -> Void)?

    /// When home already asked what we are deciding, the topic page is
    /// skipped and the party is created straight away.
    let presetTopic: String?

    init(presetTopic: String? = nil, onComplete: (() -> Void)? = nil) {
        self.presetTopic = presetTopic
        self.onComplete = onComplete
    }

    // MARK: - Constants

    private let dotSize: CGFloat = 6

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            pages

            if presetTopic == nil {
                pageIndicator
            }

            bottomButton
        }
        .task {
            if let presetTopic, viewModel.session == nil, !start {
                topic = presetTopic
                startParty(with: presetTopic)
            }
        }
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $err) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .navigationDestination(isPresented: $navSwipe) {
            SwipePartyView(viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionFinished)) { _ in
            navSwipe = false
            onComplete?()
            DispatchQueue.main.async {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var pages: some View {
        if presetTopic == nil {
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
        } else {
            PartyInvitePage(viewModel: viewModel)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            pageDot(isActive: pg == 0)

            pageDot(isActive: pg == 1)
        }
        .padding(.vertical, 10)
    }

    private var bottomButton: some View {
        Button(action: bottomButtonTapped) {
            Text(buttonText)
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Constants.Colors.orangeLight,
                            Constants.Colors.orangePrimary
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

    // MARK: - Supporting

    private func pageDot(isActive: Bool) -> some View {
        Circle()
            .frame(width: dotSize, height: dotSize)
            .foregroundColor(isActive ? .primary : .secondary.opacity(0.4))
    }

    // MARK: - Helpers

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
            guard viewModel.session != nil, !start else { return }
            start = true
            viewModel.beginSwiping { success in
                DispatchQueue.main.async {
                    start = false
                    if success {
                        navSwipe = true
                    } else {
                        err = true
                    }
                }
            }
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

#Preview {
    NavigationStack {
        PartySetupView()
    }
}
