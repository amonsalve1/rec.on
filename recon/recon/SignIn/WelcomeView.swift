//
//  WelcomeView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

struct WelcomeView: View {
    let onSignUp: () -> Void
    let onSignIn: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Text("Recommend On the go.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14).opacity(0.7))
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 80)
            
            VStack(spacing: 16) {
                Button(action: onSignUp) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.55, blue: 0.35),
                                    Color(red: 1.0, green: 0.3, blue: 0.2)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                }
                
                Button(action: onSignIn) {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.65, blue: 0.4),
                                    Color(red: 1.0, green: 0.5, blue: 0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.14, green: 0.14, blue: 0.14))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .padding(.bottom, 50)
        }
    }
}

