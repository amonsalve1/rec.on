//
//  WaitingForOthersView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

/// A holding screen shown after the user finishes swiping. It polls the
/// backend until every participant has made their final picks, then advances
/// to the spin wheel.
struct WaitingForOthersView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: PartySetupView.ViewModel

    @State private var tmr: Timer?
    @State private var navSpin = false

    let onComplete: (() -> Void)?

    init(viewModel: PartySetupView.ViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    // MARK: - Constants

    private let pollInterval: TimeInterval = 2.0
    private let spinDelay: TimeInterval = 0.5

    // MARK: - UI

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            statusHeader

            progressSection

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(CanvasBackground())
        .navigationTitle("Waiting")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
        .navigationDestination(isPresented: $navSpin) {
            SpinWheelView(
                viewModel: viewModel,
                onComplete: onComplete
            )
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.orangePrimary)

            Text("Waiting for others…")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("\(viewModel.allFinalPicks.count) of \(viewModel.session?.participants?.count ?? 0) have picked")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var progressSection: some View {
        if !viewModel.progress.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Progress")
                    .font(Constants.Fonts.bodySemibold)
                    .padding(.horizontal, 24)

                ForEach(viewModel.progress, id: \.user_id) { progress in
                    ProgressRow(progress: progress)
                }
            }
        }
    }

    // MARK: - Helpers

    private func startPolling() {
        refreshData()

        tmr = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
            refreshData()
        }
    }

    private func stopPolling() {
        tmr?.invalidate()
        tmr = nil
    }

    private func refreshData() {
        let group = DispatchGroup()

        group.enter()
        viewModel.refreshProgress {
            group.leave()
        }

        group.enter()
        viewModel.refreshFinalPicks {
            group.leave()
        }

        group.notify(queue: .main) {
            if viewModel.allParticipantsHavePicked {
                stopPolling()
                DispatchQueue.main.asyncAfter(deadline: .now() + spinDelay) {
                    navSpin = true
                }
            }
        }
    }

}

#Preview {
    NavigationStack {
        WaitingForOthersView(viewModel: PartySetupView.ViewModel())
    }
}
