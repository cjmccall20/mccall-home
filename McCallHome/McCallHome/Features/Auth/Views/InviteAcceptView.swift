//
//  InviteAcceptView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct InviteAcceptView: View {
    let token: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var invitationDetails: InvitationDetails?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isAccepting = false

    private let invitationService = InvitationService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading invitation...")
                } else if let details = invitationDetails, details.found {
                    if details.isValid == true {
                        validInvitationView(details)
                    } else {
                        invalidInvitationView(details)
                    }
                } else {
                    notFoundView
                }
            }
            .padding()
            .navigationTitle("Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadInvitation()
        }
    }

    private func validInvitationView(_ details: InvitationDetails) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.open.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("You're Invited!")
                    .font(.title2)
                    .fontWeight(.bold)

                if let householdName = details.householdName {
                    Text("Join \(householdName)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                if let invitedBy = details.invitedByName {
                    Text("Invited by \(invitedBy)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if authViewModel.isAuthenticated {
                // User is logged in - can accept directly
                acceptButton
            } else {
                // User needs to sign up or log in first
                VStack(spacing: 16) {
                    Text("Sign in or create an account to join this household")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    NavigationLink {
                        SignUpWithInviteView(token: token)
                            .environmentObject(authViewModel)
                    } label: {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        LoginWithInviteView(token: token)
                            .environmentObject(authViewModel)
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var acceptButton: some View {
        Button {
            acceptInvitation()
        } label: {
            if isAccepting {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Accept Invitation")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isAccepting)
    }

    private func invalidInvitationView(_ details: InvitationDetails) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Invitation Expired")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This invitation is no longer valid. Please ask for a new invitation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private var notFoundView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Invalid Invitation")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This invitation link is invalid or has already been used.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private func loadInvitation() async {
        isLoading = true
        do {
            invitationDetails = try await invitationService.getInvitationDetails(token: token)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func acceptInvitation() {
        guard let userId = authViewModel.currentUser?.id else { return }

        isAccepting = true
        Task {
            do {
                let result = try await invitationService.acceptInvitation(token: token, userId: userId)
                if result.success {
                    // Refresh user data to get new household
                    await authViewModel.checkSession()
                    dismiss()
                } else {
                    error = result.error ?? "Failed to accept invitation"
                }
            } catch {
                self.error = error.localizedDescription
            }
            isAccepting = false
        }
    }
}

// MARK: - Sign Up with Invite View

struct SignUpWithInviteView: View {
    let token: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    private let invitationService = InvitationService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign up to accept this invitation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocapitalization(.words)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    signUpAndAccept()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account & Join")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || name.isEmpty || email.isEmpty || password.count < 6)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signUpAndAccept() {
        isLoading = true
        error = nil

        Task {
            do {
                // Sign up the user
                authViewModel.name = name
                authViewModel.email = email
                authViewModel.password = password
                await authViewModel.signUp()

                // If sign up succeeded and we're authenticated
                if authViewModel.isAuthenticated, let userId = authViewModel.currentUser?.id {
                    // Accept the invitation
                    let result = try await invitationService.acceptInvitation(token: token, userId: userId)
                    if result.success {
                        await authViewModel.checkSession()
                        dismiss()
                    } else {
                        error = result.error ?? "Failed to join household"
                    }
                } else {
                    error = authViewModel.error ?? "Sign up failed"
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Login with Invite View

struct LoginWithInviteView: View {
    let token: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    private let invitationService = InvitationService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in to accept this invitation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    signInAndAccept()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In & Join")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signInAndAccept() {
        isLoading = true
        error = nil

        Task {
            do {
                // Sign in the user
                authViewModel.email = email
                authViewModel.password = password
                await authViewModel.signIn()

                // If sign in succeeded
                if authViewModel.isAuthenticated, let userId = authViewModel.currentUser?.id {
                    // Accept the invitation
                    let result = try await invitationService.acceptInvitation(token: token, userId: userId)
                    if result.success {
                        await authViewModel.checkSession()
                        dismiss()
                    } else {
                        error = result.error ?? "Failed to join household"
                    }
                } else {
                    error = authViewModel.error ?? "Sign in failed"
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    InviteAcceptView(token: "test-token")
        .environmentObject(AuthViewModel())
}
