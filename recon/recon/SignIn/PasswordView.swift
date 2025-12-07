//
//  PasswordView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

struct PasswordView: View {
    @Binding var password: String
    @Binding var errorMessage: String?
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 24) {
                Text("What's your password?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                
                SecureField("Password", text: $password)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(22)
                    .onChange(of: password) { _ in
                        errorMessage = nil
                    }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: onConfirm) {
                    Text("Confirm")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(password.isEmpty ? Color.gray : Color(red: 0.14, green: 0.14, blue: 0.14))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(password.isEmpty ? Color.gray.opacity(0.2) : Color.white)
                        .cornerRadius(22)
                }
                .disabled(password.isEmpty)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

