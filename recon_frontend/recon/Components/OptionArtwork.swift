//
//  OptionArtwork.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// Artwork for an option card.
///
/// When the backend supplied an image it is shown; otherwise the card gets a
/// deliberate type treatment — the option's initial, oversized, on a tinted
/// field derived from its own name. Imageless options are the common case
/// (a movie with no free-licensed still, a venue nobody has photographed),
/// so this is the designed default rather than a fallback that reads broken.
struct OptionArtwork: View {

    // MARK: - Properties

    let name: String
    let imageUrl: String?

    /// Scales the initial to the card it sits on.
    var initialSize: CGFloat = 64

    // MARK: - UI

    var body: some View {
        ZStack {
            tint

            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        initial
                    @unknown default:
                        initial
                    }
                }
            } else {
                initial
            }
        }
        .clipped()
    }

    private var tint: some View {
        LinearGradient(
            colors: palette,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var initial: some View {
        Text(initialCharacter)
            .font(.system(size: initialSize, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helpers

    private var resolvedURL: URL? {
        guard let imageUrl, imageUrl.hasPrefix("http") else { return nil }
        return URL(string: imageUrl)
    }

    /// The option's initial, skipping a leading article — otherwise half a
    /// movie deck reads "T" ("The Matrix", "The Dark Knight", "The Shawshank
    /// Redemption") and the cards stop being distinguishable.
    private var initialCharacter: String {
        let articles = ["the ", "a ", "an "]
        var trimmed = name.trimmingCharacters(in: .whitespaces)

        for article in articles where trimmed.lowercased().hasPrefix(article) {
            trimmed = String(trimmed.dropFirst(article.count))
            break
        }

        guard let first = trimmed.first ?? name.first else { return "?" }
        return String(first).uppercased()
    }

    /// Deterministic two-stop gradient per option, so the same place always
    /// wears the same colors across the deck, results, and history. Every
    /// ramp ends deep enough to hold white type and to separate from the
    /// warm canvas behind it.
    private var palette: [Color] {
        let ramps: [[Color]] = [
            [Constants.Colors.orangeLight, Constants.Colors.orangePrimary],
            [Constants.Colors.amber, Constants.Colors.orangePrimary],
            [Constants.Colors.peach, Constants.Colors.splashBottom],
            [Constants.Colors.orangePrimary, Constants.Colors.splashBottom],
            [Constants.Colors.splashTop, Constants.Colors.orangePrimary]
        ]
        let index = abs(name.hashValue) % ramps.count
        return ramps[index]
    }

}

#Preview {
    HStack(spacing: 12) {
        OptionArtwork(name: "The Matrix", imageUrl: nil)
            .frame(width: 110, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        OptionArtwork(name: "Inception", imageUrl: nil)
            .frame(width: 110, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        OptionArtwork(name: "Goodfellas", imageUrl: nil)
            .frame(width: 110, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Constants.Colors.background)
}
