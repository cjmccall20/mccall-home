//
//  SettingsView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = authViewModel.currentUser {
                        Text(user.name)
                        Text(user.email)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await authViewModel.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
