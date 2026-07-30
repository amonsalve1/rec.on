//
//  SpinWheelView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct SpinWheelView: View {
    @ObservedObject var viewModel: PartyViewModel
    let onComplete: (() -> Void)?
    
    @State private var spin = false
    @State private var w: [String: Any]?
    @State private var navRes = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: PartyViewModel, onComplete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if spin {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Spinning the wheel…")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
            } else if let w = w {
                VStack(spacing: 16) {
                    Text("Winner selected!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    if let name = w["option_name"] as? String {
                        Text(name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.35))
                    }
                    
                    Button(action: {
                        navRes = true
                    }) {
                        Text("See Results")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.75, blue: 0.4),
                                        Color(red: 1.0, green: 0.55, blue: 0.35)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(22)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            } else {
                Button(action: spinWheel) {
                    Text("Spin the Wheel!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.75, blue: 0.4),
                                    Color(red: 1.0, green: 0.55, blue: 0.35)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                }
                .padding(.horizontal, 24)
                .onAppear {
                    if !spin && w == nil {
                        spinWheel()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Color(.systemGray6).ignoresSafeArea())
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
    
    private func spinWheel() {
        spin = true
        
        viewModel.spinWheel { result in
            spin = false
            switch result {
            case .success(let data):
                w = data
                viewModel.refreshSession()
            case .failure:
                break
            }
        }
    }
    
}
