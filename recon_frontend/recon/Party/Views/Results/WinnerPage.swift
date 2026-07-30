//
//  WinnerPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Foundation

struct WinnerPage: View {
    let winner: PartyCandidate
    let onComplete: (() -> Void)?
    @State private var confetti = false
    @Environment(\.dismiss) private var dismiss
    
    init(winner: PartyCandidate, onComplete: (() -> Void)? = nil) {
        self.winner = winner
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("We have a winner!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                WinnerCard(winner: winner)

                Spacer()

                Button {
                    saveRecentPick(winner)
                    DispatchQueue.main.async {
                        if let onComplete = onComplete {
                            onComplete()
                        } else {
                            popToRoot()
                        }
                    }
                } label: {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.75, blue: 0.4),
                                        Color(red: 1.0, green: 0.55, blue: 0.35)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ConfettiView(isActive: confetti)
        }
        .onAppear {
            confetti = true
        }
    }
    
    private func saveRecentPick(_ cand: PartyCandidate) {
        var picks: [RecentPickData] = []
        if let data = UserDefaults.standard.data(forKey: "recentPicks") {
            if let decoded = try? JSONDecoder().decode([RecentPickData].self, from: data) {
                picks = decoded
            }
        }
        
        let imageUrl = cand.imageUrl ?? cand.imageName
        let newPick = RecentPickData(
            id: Int(Date().timeIntervalSince1970),
            name: cand.name,
            imageUrl: imageUrl,
            address: cand.address,
            tags: cand.tags,
            timeAgo: "Just now"
        )
        
        picks.removeAll { $0.name == cand.name && abs($0.id - newPick.id) < 2 }
        
        picks.insert(newPick, at: 0)
        if picks.count > 20 {
            picks = Array(picks.prefix(20))
        }
        
        if let encoded = try? JSONEncoder().encode(picks) {
            UserDefaults.standard.set(encoded, forKey: "recentPicks")
            NotificationCenter.default.post(name: NSNotification.Name("RecentPicksUpdated"), object: nil)
        }
    }
    
    private func popToRoot() {
        var cnt = 0
        let max = 10
        
        func dismissNext() {
            if cnt < max {
                dismiss()
                cnt += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dismissNext()
                }
            }
        }
        
        dismissNext()
    }
}
