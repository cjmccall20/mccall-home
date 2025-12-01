//
//  AuthService.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        Task {
            await observeAuthChanges()
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        let authResponse = try await supabase.auth.signUp(email: email, password: password)

        let userId = authResponse.user.id

        // Get existing household or create a new one
        let households: [Household] = try await supabase
            .from("households")
            .select()
            .limit(1)
            .execute()
            .value

        let household: Household
        if let existingHousehold = households.first {
            household = existingHousehold
        } else {
            // Create new household for first user
            let newHousehold = Household(
                id: UUID(),
                name: "\(name)'s Family",
                createdAt: Date()
            )
            try await supabase
                .from("households")
                .insert(newHousehold)
                .execute()
            household = newHousehold
        }

        // Create user profile
        let newUser = User(
            id: userId,
            householdId: household.id,
            name: name,
            email: email,
            notificationTimes: nil,
            deviceToken: nil,
            createdAt: Date()
        )

        try await supabase
            .from("users")
            .insert(newUser)
            .execute()

        currentUser = newUser
        isAuthenticated = true
    }

    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
        try await fetchCurrentUser()
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            let _ = session.user.id
            try await fetchCurrentUser()
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    private func fetchCurrentUser() async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id

        let users: [User] = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        if let user = users.first {
            currentUser = user
            isAuthenticated = true
        } else {
            throw AuthError.userNotFound
        }
    }

    private func observeAuthChanges() async {
        for await (event, _) in await supabase.auth.authStateChanges {
            switch event {
            case .signedIn:
                try? await fetchCurrentUser()
            case .signedOut:
                currentUser = nil
                isAuthenticated = false
            default:
                break
            }
        }
    }

    enum AuthError: LocalizedError {
        case signUpFailed
        case noHouseholdFound
        case userNotFound

        var errorDescription: String? {
            switch self {
            case .signUpFailed:
                return "Failed to create account"
            case .noHouseholdFound:
                return "No household found to join"
            case .userNotFound:
                return "User profile not found"
            }
        }
    }
}
