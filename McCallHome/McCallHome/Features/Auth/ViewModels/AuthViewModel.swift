//
//  AuthViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

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

    private func clearFields() {
        email = ""
        password = ""
        name = ""
    }
}
