//
//  UsernameView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

struct UsernameView: View {
    @Binding var username: String
    @Binding var errorMessage: String?
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 24) {
                Text("Choose a username")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                
                TextField("username", text: $username)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(22)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: username) { oldValue, newValue in
                        if oldValue != newValue && newValue.count > oldValue.count {
                            errorMessage = nil
                        }
                    }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: onNext) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(username.isEmpty ? Color.gray : Color(red: 0.14, green: 0.14, blue: 0.14))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(username.isEmpty ? Color.gray.opacity(0.2) : Color.white)
                        .cornerRadius(22)
                }
                .disabled(username.isEmpty)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

