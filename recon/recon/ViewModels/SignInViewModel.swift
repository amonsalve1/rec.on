//
//  SignInViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import SwiftUI

extension SignInView {

    /// The ViewModel for the sign-in flow, driving the step wizard and the
    /// register/login requests.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var currentStep: SignInStep = .welcome
        @Published var authMode: AuthMode = .signIn
        @Published var email: String = ""
        @Published var username: String = ""
        @Published var password: String = ""
        @Published var errorMessage: String?

        // MARK: - Computed Properties

        /// Number of wizard steps for the current mode (sign-up adds username).
        var totalSteps: Int {
            authMode == .signUp ? 3 : 2
        }

        /// Index of the current step within `totalSteps`, or -1 before the
        /// wizard starts.
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

        // MARK: - Navigation

        /// Resets the fields and enters the wizard in the given mode.
        func begin(_ mode: AuthMode) {
            authMode = mode
            email = ""
            username = ""
            password = ""
            errorMessage = nil
            withAnimation {
                currentStep = .email
            }
        }

        /// Advances past the email step if an email was entered.
        func advanceFromEmail() {
            guard !email.isEmpty else { return }

            errorMessage = nil
            withAnimation {
                currentStep = authMode == .signUp ? .username : .password
            }
        }

        /// Advances past the username step if a username was entered.
        func advanceFromUsername() {
            guard !username.isEmpty else { return }

            errorMessage = nil
            withAnimation {
                currentStep = .password
            }
        }

        /// Submits the password step, registering or logging in by mode.
        func submitPassword() {
            guard !password.isEmpty else { return }

            Task {
                if authMode == .signUp {
                    await performRegistration()
                } else {
                    await performLogin()
                }
            }
        }

        /// Steps back from the email step to the welcome screen.
        func goBackFromEmail() {
            withAnimation {
                currentStep = .welcome
                email = ""
                errorMessage = nil
            }
        }

        /// Steps back from the username step to the email step.
        func goBackFromUsername() {
            withAnimation {
                currentStep = .email
                username = ""
                errorMessage = nil
            }
        }

        /// Steps back from the password step to the previous step for the mode.
        func goBackFromPassword() {
            withAnimation {
                currentStep = authMode == .signUp ? .username : .email
                password = ""
                errorMessage = nil
            }
        }

        // MARK: - Requests

        /// Registers a new account, then routes to profile setup on success or
        /// back to the offending step on failure.
        func performRegistration() async {
            errorMessage = nil
            withAnimation {
                currentStep = .loading
            }

            await withCheckedContinuation { continuation in
                RecOnAPI.shared.register(
                    email: email,
                    username: username,
                    password: password
                ) { result in
                    switch result {
                    case .success(let token):
                        Task { @MainActor in
                            UserDefaults.standard.set(token, forKey: "authToken")
                            UserDefaults.standard.set(true, forKey: "needsProfileSetup")
                            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
                        }
                    case .failure(let error):
                        Task { @MainActor [weak self] in
                            self?.handleRegistrationFailure(error)
                        }
                    }
                    continuation.resume()
                }
            }
        }

        /// Logs in, persisting the token on success or surfacing the error on
        /// the password step.
        func performLogin() async {
            errorMessage = nil
            withAnimation {
                currentStep = .loading
            }

            await withCheckedContinuation { continuation in
                RecOnAPI.shared.login(email: email, password: password) { result in
                    switch result {
                    case .success(let token):
                        Task { @MainActor in
                            UserDefaults.standard.set(token, forKey: "authToken")
                            UserDefaults.standard.set(false, forKey: "needsProfileSetup")
                        }
                    case .failure(let error):
                        Task { @MainActor [weak self] in
                            self?.handleLoginFailure(error)
                        }
                    }
                    continuation.resume()
                }
            }
        }

        // MARK: - Helpers

        /// Surfaces a registration error and jumps back to the step it names.
        private func handleRegistrationFailure(_ error: Error) {
            var msg = error.localizedDescription
            if let detailed = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String {
                msg = detailed
            }

            if msg.isEmpty || msg == "The operation couldn't be completed." {
                errorMessage = "Failed to create account. Please try again."
            } else {
                errorMessage = msg
            }

            let lower = msg.lowercased()
            if lower.contains("username") || lower.contains("taken") {
                withAnimation { currentStep = .username }
            } else if lower.contains("email") || lower.contains("registered") {
                withAnimation { currentStep = .email }
            } else {
                withAnimation { currentStep = .password }
            }
        }

        /// Surfaces a login error on the password step.
        private func handleLoginFailure(_ error: Error) {
            if let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String,
               !msg.isEmpty {
                errorMessage = msg
            } else {
                errorMessage = "Invalid email or password"
            }
            currentStep = .password
        }

    }

}
