//
//  RecOnSplashView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

struct RecOnSplashView: View {
    @Binding var showSplash: Bool

    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("RecOnScriptLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 260)
                .scaleEffect(x: scale, y: 1.0)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                scale = 1.05
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.35).delay(0.6)) {
                scale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showSplash = false
                }
            }
        }
    }
}

