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
    @Published var householdJoinError: String?

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
        currentUser = try await provisionUser(
            userId: session.user.id,
            name: "Dev User",
            email: Config.devEmail,
            householdName: "Dev Household"
        )
        isAuthenticated = true
    }

    /// Create a fresh household and users row for a newly authenticated account.
    /// Every new account gets its own household; joining an existing one happens
    /// only through invitations or the join deep link.
    func provisionUser(userId: UUID, name: String, email: String, householdName: String? = nil) async throws -> User {
        let household = Household(
            id: UUID(),
            name: householdName ?? "\(name)'s Family",
            createdAt: Date()
        )
        try await supabase
            .from("households")
            .insert(household)
            .execute()

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

        return newUser
    }

    func signUp(email: String, password: String, name: String) async throws {
        let authResponse = try await supabase.auth.signUp(email: email, password: password)

        currentUser = try await provisionUser(userId: authResponse.user.id, name: name, email: email)
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
              currentUser != nil else {
            return
        }

        do {
            // Server-side RPC validates the household and updates only the
            // caller's row; direct updates to users.household_id are blocked by RLS
            try await supabase
                .rpc("join_household", params: ["target_household_id": householdId.uuidString])
                .execute()

            // Clear the pending join
            UserDefaults.standard.removeObject(forKey: "pendingHouseholdJoin")

            // Refresh user data
            try await fetchCurrentUser()

            householdJoinError = nil
            print("Successfully joined household: \(householdId)")
        } catch {
            householdJoinError = "Couldn't join the household from your invite link. Please ask for a new invitation."
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
