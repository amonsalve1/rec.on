//
//  SoloFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

/// The solo flow entry screen: pick a topic, then start a local swipe session.
struct SoloFlowView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    @State private var pg = 0
    @State private var start = false
    @State private var err = false
    @State private var navSwipe = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            topicPager

            pageIndicator

            startButton
        }
        .alert("Error", isPresented: $err) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .navigationDestination(isPresented: $navSwipe) {
            SwipeSoloView(viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionFinished)) { _ in
            // collapse the pushed stack, then leave the flow entirely
            navSwipe = false
            dismiss()
        }
        .navigationTitle("Solo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topicPager: some View {
        TabView(selection: $pg) {
            PartyTopicPage { topicKey in
                startSolo(with: topicKey)
            }
            .tag(0)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundColor(pg == 0 ? .primary : .secondary.opacity(0.4))
        }
        .padding(.vertical, 10)
    }

    private var startButton: some View {
        Button(action: bottomButtonTapped) {
            Text(start ? "Starting…" : "Start swiping")
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
        .disabled(start)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    /// The bottom button is intentionally a no-op; swiping starts from the topic page itself.
    private func bottomButtonTapped() {
    }

    /// Starts a solo session for the topic and navigates to swiping on success.
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

#Preview {
    NavigationStack {
        SoloFlowView()
    }
}
