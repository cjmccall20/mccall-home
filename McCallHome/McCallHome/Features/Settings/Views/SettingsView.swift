//
//  SettingsView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section("Profile") {
                    NavigationLink {
                        ProfileView()
                            .environmentObject(authViewModel)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                if let user = authViewModel.currentUser {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Loading...")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Household Section
                Section("Household") {
                    NavigationLink {
                        HouseholdMembersView()
                    } label: {
                        Label("Household Members", systemImage: "person.2")
                    }

                    NavigationLink {
                        PantryStaplesView()
                    } label: {
                        Label("Pantry Staples", systemImage: "archivebox")
                    }
                }

                // App Section
                Section("App") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
