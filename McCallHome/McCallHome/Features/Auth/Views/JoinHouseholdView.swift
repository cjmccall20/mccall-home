//
//  JoinHouseholdView.swift
//  McCallHome
//
//  Created by Claude on 12/8/25.
//

import SwiftUI
import Supabase

struct JoinHouseholdView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    let householdId: UUID

    @State private var householdName: String?
    @State private var isLoading = true
    @State private var isJoining = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                // Title
                Text("Join Household")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if isLoading {
                    ProgressView("Loading...")
                } else if let name = householdName {
                    VStack(spacing: 8) {
                        Text("You've been invited to join")
                            .foregroundStyle(.secondary)

                        Text(name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    if authViewModel.isAuthenticated {
                        // User is logged in - can join directly
                        VStack(spacing: 12) {
                            // Warn if they're already in a household
                            if let currentHousehold = authViewModel.currentUser?.householdId,
                               currentHousehold != householdId {
                                Text("You'll leave your current household to join this one.")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.center)
                            }

                            Button {
                                joinHousehold()
                            } label: {
                                if isJoining {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Join Household")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isJoining)
                        }
                    } else {
                        // User needs to sign up/in first
                        VStack(spacing: 12) {
                            Text("Create an account or sign in to join this household")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button {
                                // Store the household ID for after auth
                                UserDefaults.standard.set(householdId.uuidString, forKey: "pendingHouseholdJoin")
                                dismiss()
                            } label: {
                                Text("Continue")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    // Household not found
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)

                        Text("Household Not Found")
                            .font(.headline)

                        Text("This invite link may be invalid or expired.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }

                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadHousehold()
            }
        }
    }

    private func loadHousehold() async {
        isLoading = true
        do {
            // Use RPC function to bypass RLS (user can't see households they're not in yet)
            struct HouseholdResult: Decodable {
                let id: UUID
                let name: String
            }

            let result: HouseholdResult = try await supabase
                .rpc("get_household_by_id", params: ["target_household_id": householdId.uuidString])
                .execute()
                .value

            householdName = result.name
        } catch {
            // Household not found or other error
            householdName = nil
        }
        isLoading = false
    }

    private func joinHousehold() {
        guard let user = authViewModel.currentUser else { return }

        isJoining = true
        Task {
            do {
                // Update user's household_id
                try await supabase
                    .from("users")
                    .update(["household_id": householdId.uuidString])
                    .eq("id", value: user.id.uuidString)
                    .execute()

                // Refresh the user data
                await authViewModel.checkSession()

                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isJoining = false
        }
    }
}

#Preview {
    JoinHouseholdView(householdId: UUID())
        .environmentObject(AuthViewModel())
}
