//
//  SignUpView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showSignUp: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Join your family household")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Form
            VStack(spacing: 16) {
                TextField("Name", text: $authViewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocapitalization(.words)

                TextField("Email", text: $authViewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $authViewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let error = authViewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await authViewModel.signUp()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authViewModel.isLoading)
            }
            .padding(.horizontal)

            Spacer()

            // Login link
            HStack {
                Text("Already have an account?")
                    .foregroundStyle(.secondary)
                Button("Sign In") {
                    showSignUp = false
                }
            }
            .font(.subheadline)
            .padding(.bottom)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        SignUpView(showSignUp: .constant(true))
            .environmentObject(AuthViewModel())
    }
}
