//
//  OAuthButtonsView.swift
//  McCallHome
//
//  "or continue with" divider plus Apple and Google sign-in buttons,
//  shared by LoginView and SignUpView.
//

import SwiftUI
import AuthenticationServices
import GoogleSignInSwift

struct OAuthButtonsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack { Divider() }
                Text("or continue with")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                VStack { Divider() }
            }

            SignInWithAppleButton(.signIn) { request in
                authViewModel.prepareAppleSignIn(request)
            } onCompletion: { result in
                Task {
                    await authViewModel.handleAppleSignIn(result)
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 48)

            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(
                scheme: colorScheme == .dark ? .dark : .light,
                style: .wide
            )) {
                Task {
                    await authViewModel.signInWithGoogle()
                }
            }
            .frame(height: 48)
            .disabled(authViewModel.isLoading)
        }
    }
}

#Preview {
    OAuthButtonsView()
        .environmentObject(AuthViewModel())
        .padding()
}
