//
//  SoloResultsFlowView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Foundation

struct SoloResultsFlowView: View {
    let candidates: [PartyCandidate]
    let onComplete: (() -> Void)?
    
    @State private var s = 0
    @State private var w: PartyCandidate?
    @Environment(\.dismiss) private var dismiss
    
    init(candidates: [PartyCandidate], onComplete: (() -> Void)? = nil) {
        self.candidates = candidates
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            if candidates.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("No favorites selected")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("You didn't like any options.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                switch s {
                case 0:
                    PicksListPage(
                        candidates: candidates,
                        onConfirm: {
                            s = 1
                        }
                    )
                    
                case 1:
                    RandomizingPage(
                        candidates: candidates,
                        forced: nil,
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
        }
        .navigationTitle(s == 0 ? "Picks" : "Solo")
        .navigationBarTitleDisplayMode(.inline)
    }
}
