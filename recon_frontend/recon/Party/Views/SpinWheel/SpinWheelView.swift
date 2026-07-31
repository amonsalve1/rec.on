//
//  SpinWheelView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The tie-breaker step that spins a wheel over the pool of final picks and
/// reveals the winning option.
struct SpinWheelView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PartySetupView.ViewModel

    @State private var spin = false
    @State private var w: PartyCandidate?
    @State private var navRes = false
    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    init(viewModel: PartySetupView.ViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            content

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(CanvasBackground())
        .navigationTitle("Spin Wheel")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navRes) {
            PartyResultsFlowView(
                candidates: viewModel.poolOfPicks,
                backendWinner: viewModel.backendWinner,
                onComplete: onComplete
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if spin {
            spinningState
        } else if let w = w {
            winnerState(for: w)
        } else {
            spinButton
        }
    }

    private var spinningState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Spinning the wheel…")
                .font(.system(size: 18, weight: .medium, design: .rounded))
        }
    }

    private var spinButton: some View {
        Button(action: spinWheel) {
            Text("Spin the Wheel!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(buttonGradient)
                .cornerRadius(22)
        }
        .padding(.horizontal, 24)
        .onAppear {
            if !spin && w == nil {
                spinWheel()
            }
        }
    }

    // MARK: - Supporting

    private func winnerState(for w: PartyCandidate) -> some View {
        VStack(spacing: 16) {
            Text("Winner selected!")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(w.name)
                .font(Constants.Fonts.subheading)
                .foregroundColor(Constants.Colors.orangePrimary)

            Button(action: {
                navRes = true
            }) {
                Text("See Results")
                    .font(Constants.Fonts.bodySemibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(buttonGradient)
                    .cornerRadius(22)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    private var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Constants.Colors.orangeLight,
                Constants.Colors.orangePrimary
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Helpers

    private func spinWheel() {
        spin = true

        viewModel.spinWheel { success in
            spin = false
            if success {
                w = viewModel.backendWinner
            }
        }
    }

}

#Preview {
    NavigationStack {
        SpinWheelView(viewModel: PartySetupView.ViewModel())
    }
}
