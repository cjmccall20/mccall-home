//
//  AuthViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    /// Raw nonce for the in-flight Sign in with Apple request
    private var currentAppleNonce: String?

    init() {
        // Observe auth service state
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentUser)
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.signIn(email: email, password: password)
            clearFields()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            error = "Please fill in all fields"
            return
        }

        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.signUp(email: email, password: password, name: name)
            clearFields()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign in with Apple

    /// Configure the Apple authorization request: Apple gets the SHA256-hashed
    /// nonce; the raw nonce is kept to hand to Supabase on completion.
    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256Hex(nonce)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentAppleNonce else {
                error = "Apple sign-in failed. Please try again."
                return
            }

            isLoading = true
            error = nil
            do {
                try await authService.signInWithApple(
                    idToken: idToken,
                    nonce: nonce,
                    fullName: credential.fullName
                )
                clearFields()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false

        case .failure(let failure):
            // User dismissing the sheet isn't an error worth showing
            if let authError = failure as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            error = failure.localizedDescription
        }
        currentAppleNonce = nil
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async {
        guard let presenter = Self.topViewController() else {
            error = "Couldn't start Google sign-in. Please try again."
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.signInWithGoogle(presenting: presenter)
            clearFields()
        } catch GIDSignInError.canceled {
            // User dismissed the Google sheet - not an error
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windowScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first,
              var top = window.rootViewController else {
            return nil
        }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    // MARK: - Nonce helpers

    private static func randomNonceString(length: Int = 32) -> String {
        // SystemRandomNumberGenerator is cryptographically secure
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._"
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }

    private static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteAccount() async {
        isLoading = true
        error = nil

        do {
            try await authService.deleteAccount()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func checkSession() async {
        if Config.skipAuthForDevelopment {
            await authService.setupDevMode()
        } else {
            await authService.checkSession()
        }
    }

    // MARK: - Password Reset

    func requestPasswordReset(email: String) async {
        guard !email.isEmpty else {
            error = "Please enter your email address"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.resetPassword(email: email)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func updatePassword(newPassword: String) async {
        guard newPassword.count >= 6 else {
            error = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.updatePassword(newPassword: newPassword)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func clearFields() {
        email = ""
        password = ""
        name = ""
    }
}
