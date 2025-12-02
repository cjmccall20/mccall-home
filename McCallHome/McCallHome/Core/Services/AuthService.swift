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
            if !Config.skipAuthForDevelopment {
                await observeAuthChanges()
            }
        }
    }

    // MARK: - Development Mode

    /// Set up dev mode with a test household (no real auth required)
    /// Note: profiles table requires auth.users FK, so we skip profile creation
    /// and make created_by nullable in tasks model instead
    func setupDevMode() async {
        guard Config.skipAuthForDevelopment else { return }

        do {
            // Ensure dev household exists in DB
            let households: [Household] = try await supabase
                .from("households")
                .select()
                .eq("id", value: Config.devHouseholdId.uuidString)
                .execute()
                .value

            if households.isEmpty {
                // Create dev household
                let devHousehold = Household(
                    id: Config.devHouseholdId,
                    name: "Dev Household",
                    createdAt: Date()
                )
                try await supabase
                    .from("households")
                    .insert(devHousehold)
                    .execute()
                print("✅ Created dev household")
            }

            // Set the current user (profile not stored in DB due to auth.users FK constraint)
            currentUser = User(
                id: Config.devUserId,
                householdId: Config.devHouseholdId,
                name: "Dev User",
                email: "dev@test.com",
                notificationTimes: nil,
                deviceToken: nil,
                createdAt: Date()
            )
            isAuthenticated = true
            print("✅ Dev mode enabled with household: \(Config.devHouseholdId)")
        } catch {
            print("❌ Failed to setup dev mode: \(error)")
            // Even if DB setup fails, we can still use local dev user for UI testing
            currentUser = User(
                id: Config.devUserId,
                householdId: Config.devHouseholdId,
                name: "Dev User",
                email: "dev@test.com",
                notificationTimes: nil,
                deviceToken: nil,
                createdAt: Date()
            )
            isAuthenticated = true
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

    func deleteAccount() async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.userNotFound
        }

        // Delete user data from our tables (cascade will handle related data)
        try await supabase
            .from("users")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()

        // Sign out locally
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false

        // Note: Actual auth.users deletion requires admin API or Edge Function
        // The user record in Supabase Auth will be orphaned but unusable
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
