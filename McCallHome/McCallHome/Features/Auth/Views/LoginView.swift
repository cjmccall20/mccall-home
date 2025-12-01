//
//  LoginView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showSignUp: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("McCall Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Family household management")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $authViewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $authViewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let error = authViewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await authViewModel.signIn()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authViewModel.isLoading)
            }
            .padding(.horizontal)

            Spacer()

            // Sign up link
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)
                Button("Sign Up") {
                    showSignUp = true
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
        LoginView(showSignUp: .constant(false))
            .environmentObject(AuthViewModel())
    }
}
