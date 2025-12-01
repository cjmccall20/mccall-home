//
//  ProfileView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name: String = ""
    @State private var isEditing = false
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("Name") {
                if isEditing {
                    TextField("Name", text: $name)
                } else {
                    Text(authViewModel.currentUser?.name ?? "")
                }
            }

            Section("Email") {
                Text(authViewModel.currentUser?.email ?? "")
                    .foregroundStyle(.secondary)
                Text("Email cannot be changed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Account Info") {
                if let user = authViewModel.currentUser {
                    LabeledContent("Member since", value: user.createdAt.formatted(as: .medium))
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || isSaving)
                } else {
                    Button("Edit") {
                        name = authViewModel.currentUser?.name ?? ""
                        isEditing = true
                    }
                }
            }
        }
        .onAppear {
            name = authViewModel.currentUser?.name ?? ""
        }
    }

    private func saveProfile() {
        // Note: Would need to implement update user in AuthService
        // For now, just toggle editing off
        isEditing = false
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
