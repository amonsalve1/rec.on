//
//  SoloResultsFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The solo results flow: the liked picks, the randomizer, and the winner
/// reveal. The winner comes from the backend spin; the randomizer animation
/// is forced to land on it.
struct SoloResultsFlowView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: SoloFlowView.ViewModel

    @State private var s = 0
    @State private var w: PartyCandidate?
    @State private var spinning = false
    @State private var spinErr = false

    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    init(viewModel: SoloFlowView.ViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            Constants.Colors.background.ignoresSafeArea()

            if viewModel.liked.isEmpty {
                emptyState
            } else {
                stepContent
            }
        }
        .navigationTitle(s == 0 ? "Picks" : "Solo")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $spinErr) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("No favorites selected")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Text("You didn't like any options.")
                .font(Constants.Fonts.label)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch s {
        case 0:
            if spinning {
                spinningState
            } else {
                PicksListPage(
                    candidates: viewModel.liked,
                    onConfirm: {
                        spinForWinner()
                    }
                )
            }

        case 1:
            RandomizingPage(
                candidates: viewModel.liked,
                forced: w,
                onFinished: { selected in
                    w = selected
                    s = 2
                }
            )

        case 2:
            if let w {
                WinnerPage(winner: w) {
                    onComplete?()
                }
            }

        default:
            EmptyView()
        }
    }

    private var spinningState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Picking a winner…")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    /// Asks the backend for the winner, then runs the randomizer animation
    /// forced to land on it.
    private func spinForWinner() {
        spinning = true

        viewModel.spin { winner in
            spinning = false
            if let winner {
                w = winner
                s = 1
            } else {
                spinErr = true
            }
        }
    }

}

#Preview {
    NavigationStack {
        SoloResultsFlowView(viewModel: SoloFlowView.ViewModel())
    }
}
