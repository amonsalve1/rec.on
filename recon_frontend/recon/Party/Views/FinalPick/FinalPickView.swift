//
//  FinalPickView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

/// The step after swiping where a member confirms the single liked option
/// that enters the party's shared pool.
struct FinalPickView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PartySetupView.ViewModel

    @State private var sel: PartyCandidate?
    @State private var sub = false
    @State private var navWait = false
    @Environment(\.dismiss) private var dismiss

    let onComplete: (() -> Void)?

    init(viewModel: PartySetupView.ViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your pick")
                .font(Constants.Fonts.title)

            Text("Choose ONE option to enter the pool")
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(.secondary)

            if viewModel.likedOptions.isEmpty {
                emptyState
            } else {
                pickSection
            }

            Spacer()

            confirmButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Constants.Colors.background.ignoresSafeArea())
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("No favorites selected")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Text("You didn't like any options. You'll be skipped in the final pick.")
                .font(Constants.Fonts.label)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }

    @ViewBuilder
    private var pickSection: some View {
        let pick = sel ?? viewModel.likedOptions.first

        if let pick = pick {
            VStack(spacing: 16) {
                Text("This will be your ONE pick in the pool:")
                    .font(Constants.Fonts.labelMedium)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                SelectablePickCard(
                    candidate: pick,
                    selected: true
                ) {
                    cyclePick(after: pick)
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

    private var confirmButton: some View {
        Button(action: submitPick) {
            Text(sub ? "Submitting…" : "Confirm Pick")
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: sel != nil ? [
                            Constants.Colors.orangeLight,
                            Constants.Colors.orangePrimary
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

    // MARK: - Helpers

    private func cyclePick(after pick: PartyCandidate) {
        if viewModel.likedOptions.count > 1 {
            if let i = viewModel.likedOptions.firstIndex(where: { $0.id == pick.id }) {
                let next = (i + 1) % viewModel.likedOptions.count
                sel = viewModel.likedOptions[next]
            }
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

/// A tappable card showing one liked candidate, with a checkmark when it is
/// the current final pick.
struct SelectablePickCard: View {

    // MARK: - Properties

    let candidate: PartyCandidate
    let selected: Bool
    let action: () -> Void

    // MARK: - Constants

    private let imageCornerRadius: CGFloat = 12

    // MARK: - UI

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                thumbnail
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius))

                details

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Constants.Fonts.iconLarge)
                        .foregroundColor(Constants.Colors.orangePrimary)
                }
            }
            .padding()
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
        Group {
            if let imageUrl = candidate.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_), .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: imageCornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Constants.Colors.orangeLight,
                        Constants.Colors.orangePrimary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(candidate.name)
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.primary)

            if !candidate.address.isEmpty {
                Text(candidate.address)
                    .font(Constants.Fonts.label)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selected ? Constants.Colors.orangePrimary : Color.clear,
                        lineWidth: 2
                    )
            )
    }

}

#Preview {
    NavigationStack {
        FinalPickView(viewModel: PartySetupView.ViewModel())
    }
}

#Preview("Selectable pick card") {
    SelectablePickCard(
        candidate: PartyCandidate(
            name: "Sample Spot",
            address: "123 Main St",
            tags: ["Cozy", "Cheap"],
            imageName: ""
        ),
        selected: true
    ) {}
    .padding()
    .background(Constants.Colors.background)
}
