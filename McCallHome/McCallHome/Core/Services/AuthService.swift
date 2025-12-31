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

    /// Set up dev mode - auto sign-in with dev credentials so RLS works
    func setupDevMode() async {
        guard Config.skipAuthForDevelopment else { return }

        do {
            // Try to sign in with dev credentials (creates session so auth.uid() works)
            try await supabase.auth.signIn(
                email: Config.devEmail,
                password: Config.devPassword
            )

            // Try to fetch existing user profile
            do {
                try await fetchCurrentUser()
                print("✅ Dev mode: signed in as \(currentUser?.email ?? "unknown")")
            } catch AuthError.userNotFound {
                // User exists in auth but not in users table - create profile
                print("📝 Creating user profile for dev account...")
                try await createDevUserProfile()
                print("✅ Dev mode: created and signed in as \(currentUser?.email ?? "unknown")")
            }
        } catch {
            print("⚠️ Dev auto-sign-in failed: \(error)")
            print("💡 Make sure Config.devEmail and Config.devPassword are set to a real account")

            // Fallback to local-only mode (RLS won't work but UI will)
            currentUser = User(
                id: Config.devUserId,
                householdId: Config.devHouseholdId,
                name: "Dev User (offline)",
                email: "dev@test.com",
                notificationTimes: nil,
                deviceToken: nil,
                createdAt: Date()
            )
            isAuthenticated = true
        }
    }

    /// Create a user profile for the dev account (when auth exists but profile doesn't)
    private func createDevUserProfile() async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id

        // Get or create a household
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
            // Create new household
            let newHousehold = Household(
                id: UUID(),
                name: "Dev Household",
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
            name: "Dev User",
            email: Config.devEmail,
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

        // Process any pending household join from deep link
        await processPendingHouseholdJoin()
    }

    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
        try await fetchCurrentUser()

        // Process any pending household join from deep link
        await processPendingHouseholdJoin()
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

    // MARK: - Pending Household Join

    /// Check for and process any pending household join from deep link
    func processPendingHouseholdJoin() async {
        guard let pendingJoinString = UserDefaults.standard.string(forKey: "pendingHouseholdJoin"),
              let householdId = UUID(uuidString: pendingJoinString),
              let userId = currentUser?.id else {
            return
        }

        do {
            // Update user's household_id
            try await supabase
                .from("users")
                .update(["household_id": householdId.uuidString])
                .eq("id", value: userId.uuidString)
                .execute()

            // Clear the pending join
            UserDefaults.standard.removeObject(forKey: "pendingHouseholdJoin")

            // Refresh user data
            try await fetchCurrentUser()

            print("Successfully joined household: \(householdId)")
        } catch {
            print("Failed to process pending household join: \(error)")
        }
    }

    // MARK: - Password Reset

    /// Request password reset email
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "homerun://reset-password")
        )
    }

    /// Update password (called after user clicks reset link)
    func updatePassword(newPassword: String) async throws {
        try await supabase.auth.update(user: .init(password: newPassword))
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
