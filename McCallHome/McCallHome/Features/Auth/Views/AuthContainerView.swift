//
//  AuthContainerView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct AuthContainerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
                    .environmentObject(authViewModel)
            } else {
                LoginView(showSignUp: $showSignUp)
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AuthViewModel())
}
