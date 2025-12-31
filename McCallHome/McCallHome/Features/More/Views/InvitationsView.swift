//
//  InvitationsView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import Supabase
import Combine

struct InvitationsView: View {
    @StateObject private var viewModel = InvitationsViewModel()

    var body: some View {
        List {
            // Invite Section
            Section {
                // Share Invite Link
                Button {
                    viewModel.shareHouseholdInvite()
                } label: {
                    HStack {
                        Image(systemName: "link")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share Invite Link")
                                .font(.headline)
                            Text("Share via iMessage, WhatsApp, or any app")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            } footer: {
                Text("Send the link to anyone you want to invite to your household.")
            }

            // Household Members Section
            if !viewModel.householdMembers.isEmpty {
                Section("Household Members") {
                    ForEach(viewModel.householdMembers) { member in
                        HStack {
                            Text(member.initial)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(colorForMember(member))
                                .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .font(.subheadline)
                                if member.id == viewModel.currentUserId {
                                    Text("You")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Pending Invitations (if any)
            if !viewModel.pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(viewModel.pendingInvitations) { invitation in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(invitation.email)
                                    .font(.subheadline)
                                Text("Expires \(invitation.expiresAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                Task {
                                    await viewModel.revokeInvitation(invitation)
                                }
                            } label: {
                                Text("Revoke")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            // Leave Household Section
            if viewModel.householdMembers.count > 1 {
                Section {
                    Button(role: .destructive) {
                        viewModel.showLeaveConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Leave Household")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("You'll be moved to your own new household. Your data will stay with your current household.")
                }
            }
        }
        .confirmationDialog(
            "Leave Household?",
            isPresented: $viewModel.showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave and Create New Household", role: .destructive) {
                Task {
                    await viewModel.leaveHousehold()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be moved to a new household. Your recipes, meal plans, and other data will stay with your current household.")
        }
        .navigationTitle("Household")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }

    private func colorForMember(_ member: HouseholdMember) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        let index = abs(member.id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - ViewModel

@MainActor
class InvitationsViewModel: ObservableObject {
    @Published var householdMembers: [HouseholdMember] = []
    @Published var pendingInvitations: [HouseholdInvitation] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showLeaveConfirmation = false

    private let invitationService = InvitationService.shared
    private let authService = AuthService.shared

    var currentUserId: UUID? {
        authService.currentUser?.id
    }

    func loadData() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        isLoading = true
        do {
            // Load household members
            householdMembers = try await HouseholdMemberService.shared.fetchMembers(for: householdId)

            // Load pending invitations
            let allInvitations = try await invitationService.fetchInvitations(for: householdId)
            pendingInvitations = allInvitations.filter { $0.status == .pending && !$0.isExpired }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func shareHouseholdInvite() {
        guard let user = authService.currentUser else { return }

        // Create a simple invite link with household ID
        let inviteLink = "homerun://join?household=\(user.householdId.uuidString)"

        let activityVC = UIActivityViewController(
            activityItems: [
                "Join my household on HomeRun! 🏠",
                URL(string: inviteLink)!
            ],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    func revokeInvitation(_ invitation: HouseholdInvitation) async {
        do {
            try await invitationService.revokeInvitation(invitation.id)
            if let index = pendingInvitations.firstIndex(where: { $0.id == invitation.id }) {
                pendingInvitations.remove(at: index)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func leaveHousehold() async {
        guard let user = authService.currentUser else { return }

        do {
            // Create a new household for the user
            let newHouseholdId = UUID()
            let newHousehold: [String: String] = [
                "id": newHouseholdId.uuidString,
                "name": "\(user.name)'s Household"
            ]

            try await supabase
                .from("households")
                .insert(newHousehold)
                .execute()

            // Update user's household_id to the new household
            try await supabase
                .from("users")
                .update(["household_id": newHouseholdId.uuidString])
                .eq("id", value: user.id.uuidString)
                .execute()

            // Refresh auth to get updated user data
            await authService.checkSession()

            // Reload data
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

}

#Preview {
    NavigationStack {
        InvitationsView()
    }
}
