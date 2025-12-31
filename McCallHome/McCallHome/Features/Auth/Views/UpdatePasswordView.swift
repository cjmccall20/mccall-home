//
//  UpdatePasswordView.swift
//  McCallHome
//
//  Created by Claude on 12/22/25.
//

import SwiftUI

struct UpdatePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordUpdated = false
    @State private var localError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: passwordUpdated ? "checkmark.circle.fill" : "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(passwordUpdated ? .green : .blue)

                Text(passwordUpdated ? "Password Updated!" : "Create New Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if passwordUpdated {
                    Text("You can now sign in with your new password")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !passwordUpdated {
                    VStack(spacing: 16) {
                        SecureField("New Password", text: $newPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)

                        if let error = localError ?? authViewModel.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            updatePassword()
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Update Password")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(authViewModel.isLoading || newPassword.isEmpty)
                    }
                    .padding(.horizontal)
                } else {
                    Button("Continue") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func updatePassword() {
        localError = nil
        authViewModel.error = nil

        guard newPassword == confirmPassword else {
            localError = "Passwords don't match"
            return
        }

        guard newPassword.count >= 6 else {
            localError = "Password must be at least 6 characters"
            return
        }

        Task {
            await authViewModel.updatePassword(newPassword: newPassword)
            if authViewModel.error == nil {
                passwordUpdated = true
            }
        }
    }
}

#Preview {
    UpdatePasswordView()
        .environmentObject(AuthViewModel())
}
