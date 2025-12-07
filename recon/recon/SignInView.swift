//
//  SignInView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/26/2024.
//

import SwiftUI

struct SignInView: View {
    @State private var currentStep: SignInStep = .welcome
    @State private var authMode: AuthMode = .signIn
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @AppStorage("needsProfileSetup") var needsProfileSetup = false
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                if currentStep == .welcome {
                    welcomeView
                } else if currentStep == .email {
                    emailView
                } else if currentStep == .username {
                    usernameView
                } else if currentStep == .password {
                    passwordView
                } else if currentStep == .loading {
                    loadingView
                }
                
                Spacer()
                
                if currentStep != .welcome && currentStep != .loading {
                    let totalSteps = authMode == .signUp ? 3 : 2
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps) { index in
                            Circle()
                                .fill(index <= stepIndex ? Color(red: 0.14, green: 0.14, blue: 0.14) : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 50)
                } else if currentStep == .loading {
                    let totalSteps = authMode == .signUp ? 3 : 2
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    var stepIndex: Int {
        switch currentStep {
        case .welcome: 
            return -1
        case .email: 
            return 0
        case .username: 
            return authMode == .signUp ? 1 : -1
        case .password: 
            return authMode == .signUp ? 2 : 1
        case .loading: 
            return authMode == .signUp ? 3 : 2
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Text("Recommend On the go.")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 80)
            
            VStack(spacing: 16) {
                Button(action: {
                    authMode = .signUp
                    email = ""
                    username = ""
                    password = ""
                    errorMessage = nil
                    withAnimation {
                        currentStep = .email
                    }
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.orange)
                        .cornerRadius(22)
                }
                
                Button(action: {
                    authMode = .signIn
                    email = ""
                    username = ""
                    password = ""
                    errorMessage = nil
                    withAnimation {
                        currentStep = .email
                    }
                }) {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.orange.opacity(0.9))
                        .cornerRadius(20)
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
    
    private var emailView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation {
                        currentStep = .welcome
                        email = ""
                        errorMessage = nil
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .padding(.leading, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 24) {
                Text("What's your email?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                
                TextField("email@example.com", text: $email)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(22)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .onChange(of: email) { _, _ in
                        errorMessage = nil
                    }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    guard !email.isEmpty else { return }
                    errorMessage = nil
                    withAnimation {
                        if authMode == .signUp {
                            currentStep = .username
                        } else {
                            currentStep = .password
                        }
                    }
                }) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(email.isEmpty ? .gray : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(email.isEmpty ? Color.gray.opacity(0.2) : Color.white)
                    .cornerRadius(22)
                }
                .disabled(email.isEmpty)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var usernameView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation {
                        currentStep = .email
                        username = ""
                        errorMessage = nil
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .padding(.leading, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 24) {
                Text("Pick a username")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
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
                
                Button(action: {
                    guard !username.isEmpty else { return }
                    errorMessage = nil
                    withAnimation {
                        currentStep = .password
                    }
                }) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(username.isEmpty ? .gray : .black)
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
    
    private var passwordView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation {
                        if authMode == .signUp {
                            currentStep = .username
                        } else {
                            currentStep = .email
                        }
                        password = ""
                        errorMessage = nil
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .padding(.leading, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            
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
                
                Button(action: {
                    if !password.isEmpty {
                        Task {
                            if authMode == .signUp {
                                await performRegistration()
                            } else {
                                await performLogin()
                            }
                        }
                    }
                }) {
                    Text("Confirm")
                        .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(password.isEmpty ? .gray : .black)
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
    
    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 12) {
                Text("Logging in...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 32)
                
                Text("Just a sec")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    func performRegistration() async {
        await MainActor.run {
            errorMessage = nil
            withAnimation {
                currentStep = .loading
            }
        }
        
        await withCheckedContinuation { continuation in
            RecOnAPI.shared.register(email: email, username: username, password: password) { result in
                if case .success(let token) = result {
                    Task { @MainActor in
                        authToken = token
                        UserDefaults.standard.set(token, forKey: "authToken")
                        needsProfileSetup = true
                        hasSeenOnboarding = false
                    }
                } else if case .failure(let error) = result {
                    var msg = error.localizedDescription
                    if let nsError = error as NSError? {
                        if let detailed = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            msg = detailed
                        }
                    }
                    
                    Task { @MainActor in
                        let finalMsg: String
                        if msg.isEmpty || msg == "The operation couldn't be completed." {
                            finalMsg = "Failed to create account. Please try again."
                        } else {
                            finalMsg = msg
                        }
                        errorMessage = finalMsg
                        
                        let lower = msg.lowercased()
                        if lower.contains("username") || lower.contains("taken") {
                            withAnimation { currentStep = .username }
                        } else if lower.contains("email") || lower.contains("registered") {
                            withAnimation { currentStep = .email }
                        } else {
                            withAnimation { currentStep = .password }
                        }
                    }
                }
                continuation.resume()
            }
        }
    }
    
    func performLogin() async {
        await MainActor.run {
            errorMessage = nil
            withAnimation {
                currentStep = .loading
            }
        }
        
        await withCheckedContinuation { continuation in
            RecOnAPI.shared.login(email: email, password: password) { result in
                switch result {
                case .success(let token):
                    Task { @MainActor in
                        authToken = token
                        UserDefaults.standard.set(token, forKey: "authToken")
                        needsProfileSetup = false
                    }
                case .failure(let error):
                    Task { @MainActor in
                        if let nsError = error as NSError?,
                           let msg = nsError.userInfo[NSLocalizedDescriptionKey] as? String,
                           !msg.isEmpty {
                            errorMessage = msg
                        } else {
                            errorMessage = "Invalid email or password"
                        }
                        currentStep = .password
                    }
                }
                continuation.resume()
            }
        }
    }
}

