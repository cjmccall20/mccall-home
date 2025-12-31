//
//  ForgotPasswordView.swift
//  McCallHome
//
//  Created by Claude on 12/22/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var emailSent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: emailSent ? "envelope.badge.fill" : "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundStyle(emailSent ? .green : .blue)

                // Title
                Text(emailSent ? "Check Your Email" : "Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(emailSent
                     ? "We've sent a password reset link to \(email)"
                     : "Enter your email and we'll send you a link to reset your password")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                if !emailSent {
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        if let error = authViewModel.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                await authViewModel.requestPasswordReset(email: email)
                                if authViewModel.error == nil {
                                    emailSent = true
                                }
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Send Reset Link")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(authViewModel.isLoading || email.isEmpty)
                    }
                    .padding(.horizontal)
                } else {
                    Button("Back to Login") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
