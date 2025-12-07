//
//  ProfileSetupView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct ProfileSetupView: View {
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("needsProfileSetup") private var needsProfileSetup = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Complete Your Profile")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 32) {
                    Image("RecOnLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 24) {
                        Text("Tell us about yourself")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                            .multilineTextAlignment(.center)
                        
                        TextField("Your name", text: $name)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .onChange(of: name) { _ in
                                errorMessage = nil
                            }
                        
                        TextField("Your location", text: $location)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .onChange(of: location) { _ in
                                errorMessage = nil
                            }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            if !name.isEmpty {
                                Task {
                                    await saveProfile()
                                }
                            }
                        }) {
                            Text(isLoading ? "Saving..." : "Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(name.isEmpty || isLoading ? Color.gray : Color(red: 0.14, green: 0.14, blue: 0.14))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .disabled(name.isEmpty || isLoading)
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
            }
        }
    }
    
    private func saveProfile() async {
        await MainActor.run {
            errorMessage = nil
            isLoading = true
        }
        
        UserDefaults.standard.set(name, forKey: "userName")
        if !location.isEmpty {
            UserDefaults.standard.set(location, forKey: "userLocation")
        } else {
            UserDefaults.standard.removeObject(forKey: "userLocation")
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            isLoading = false
            needsProfileSetup = false
        }
    }
}

