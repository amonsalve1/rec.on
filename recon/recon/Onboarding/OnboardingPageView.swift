//
//  OnboardingPageView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnScriptLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 300)
                .padding(.bottom, 40)
            
            if let emoji = page.emoji {
                Text(emoji)
                    .font(.system(size: 80))
                    .padding(.bottom, 24)
            }
            
            Text(page.largeText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, page.smallText != nil || page.bulletPoints != nil ? 16 : 0)
            
            if let smallText = page.smallText {
                Text(smallText)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 16)
            }
            
            if let bulletPoints = page.bulletPoints {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(bulletPoints) { bullet in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: bullet.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.4))
                                .frame(width: 24)
                            
                            Text(bullet.text)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

