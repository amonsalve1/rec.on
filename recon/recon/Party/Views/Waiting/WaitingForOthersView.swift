//
//  WaitingForOthersView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/4/2024.
//

import SwiftUI

struct WaitingForOthersView: View {
    @ObservedObject var viewModel: PartyViewModel
    let onComplete: (() -> Void)?
    
    @State private var tmr: Timer?
    @State private var navSpin = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: PartyViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "hourglass")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.35))
                
                Text("Waiting for others…")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("\(viewModel.allFinalPicks.count) of \(viewModel.session?.participants?.count ?? 0) have picked")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            if !viewModel.progress.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 24)
                    
                    ForEach(viewModel.progress, id: \.user_id) { progress in
                        ProgressRow(progress: progress)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Color(.systemGray6).ignoresSafeArea())
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
    
    private func startPolling() {
        refreshData()
        
        tmr = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navSpin = true
                }
            }
        }
    }
}
