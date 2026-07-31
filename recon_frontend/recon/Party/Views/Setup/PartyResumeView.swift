//
//  PartyResumeView.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// Opens a party that is already under way and drops the member back where
/// they left it: the lobby, the middle of the deck, the pick screen, or the
/// waiting room.
struct PartyResumeView: View {

    // MARK: - Properties

    let summary: PartySummaryDTO

    @StateObject private var viewModel = PartySetupView.ViewModel()

    @State private var target: PartySetupView.ViewModel.Resume?
    @State private var failed = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - UI

    var body: some View {
        ZStack {
            Constants.Colors.background.ignoresSafeArea()

            if let target {
                destination(for: target)
            } else if failed {
                failureState
            } else {
                loadingState
            }
        }
        .navigationTitle(summary.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard target == nil, !failed else { return }
            viewModel.resume(summary: summary) { resolved in
                if let resolved {
                    target = resolved
                } else {
                    failed = true
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.3)

            Text("Picking up where you left off…")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)
        }
    }

    private var failureState: some View {
        VStack(spacing: 14) {
            Text("Couldn't open that party")
                .font(Constants.Fonts.bodySemibold)

            Text(viewModel.errorMessage ?? "It may have ended.")
                .font(Constants.Fonts.label)
                .foregroundColor(.secondary)

            Button("Back") {
                dismiss()
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Supporting

    @ViewBuilder
    private func destination(for target: PartySetupView.ViewModel.Resume) -> some View {
        switch target {
        case .lobby:
            PartyInvitePage(viewModel: viewModel)

        case .swiping(let startIndex):
            SwipePartyView(viewModel: viewModel, startIndex: startIndex)

        case .pick:
            FinalPickView(viewModel: viewModel)

        case .waiting:
            WaitingForOthersView(viewModel: viewModel)
        }
    }

}

#Preview {
    NavigationStack {
        PartyResumeView(
            summary: PartySummaryDTO(
                id: "abc",
                title: "Dinner",
                topic: "restaurant",
                state: "swiping",
                optionCount: 8,
                memberCount: 2,
                submittedCount: 0,
                members: [],
                viewer: .init(swipedCount: 0, hasPicked: false)
            )
        )
    }
}
