//
//  InvitationsView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import Combine

struct InvitationsView: View {
    @StateObject private var viewModel = InvitationsViewModel()
    @State private var showInviteSheet = false

    var body: some View {
        List {
            // Invite Section
            Section {
                Button {
                    showInviteSheet = true
                } label: {
                    Label("Invite Someone", systemImage: "plus.circle.fill")
                }
            } footer: {
                Text("Invite family members or friends to join your household.")
            }

            // Pending Invitations
            if !viewModel.pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(viewModel.pendingInvitations) { invitation in
                        InvitationRow(invitation: invitation, viewModel: viewModel)
                    }
                }
            }

            // Past Invitations
            if !viewModel.pastInvitations.isEmpty {
                Section("Past Invitations") {
                    ForEach(viewModel.pastInvitations) { invitation in
                        InvitationRow(invitation: invitation, viewModel: viewModel, showActions: false)
                    }
                }
            }

            // Empty State
            if viewModel.invitations.isEmpty && !viewModel.isLoading {
                Section {
                    ContentUnavailableView(
                        "No Invitations",
                        systemImage: "envelope.badge",
                        description: Text("Invite family members to join your household")
                    )
                }
            }
        }
        .navigationTitle("Invitations")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInvitations()
        }
        .refreshable {
            await viewModel.loadInvitations()
        }
        .sheet(isPresented: $showInviteSheet) {
            SendInviteView(viewModel: viewModel) {
                showInviteSheet = false
            }
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
}

// MARK: - Invitation Row

struct InvitationRow: View {
    let invitation: HouseholdInvitation
    @ObservedObject var viewModel: InvitationsViewModel
    var showActions: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(invitation.email)
                    .font(.headline)

                Spacer()

                StatusBadge(status: invitation.status)
            }

            HStack {
                Text("Sent \(invitation.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if invitation.status == .pending {
                    Text("•")
                        .foregroundStyle(.secondary)

                    if invitation.isExpired {
                        Text("Expired")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("Expires \(invitation.expiresAt, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if showActions && invitation.status == .pending && !invitation.isExpired {
                HStack(spacing: 12) {
                    Button {
                        viewModel.shareInvitation(invitation)
                    } label: {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        Task {
                            await viewModel.revokeInvitation(invitation)
                        }
                    } label: {
                        Label("Revoke", systemImage: "xmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: InvitationStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        case .revoked: return .gray
        }
    }
}

// MARK: - Send Invite View

struct SendInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: InvitationsViewModel
    let onComplete: () -> Void

    @State private var email = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("Email Address")
                } footer: {
                    Text("We'll send an invitation link to this email address.")
                }

                Section {
                    Button {
                        sendInvite()
                    } label: {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView()
                            } else {
                                Text("Send Invitation")
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || !email.contains("@") || isSending)
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sendInvite() {
        isSending = true
        Task {
            await viewModel.sendInvitation(to: email)
            isSending = false
            if viewModel.error == nil {
                onComplete()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class InvitationsViewModel: ObservableObject {
    @Published var invitations: [HouseholdInvitation] = []
    @Published var isLoading = false
    @Published var error: String?

    private let invitationService = InvitationService.shared
    private let authService = AuthService.shared

    var pendingInvitations: [HouseholdInvitation] {
        invitations.filter { $0.status == .pending && !$0.isExpired }
    }

    var pastInvitations: [HouseholdInvitation] {
        invitations.filter { $0.status != .pending || $0.isExpired }
    }

    func loadInvitations() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        isLoading = invitations.isEmpty
        do {
            invitations = try await invitationService.fetchInvitations(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func sendInvitation(to email: String) async {
        guard let user = authService.currentUser else { return }

        do {
            let invitation = try await invitationService.createInvitation(
                email: email,
                householdId: user.householdId,
                invitedBy: user.id
            )

            // Trigger email sending via Edge Function
            // For now, just add to local list and share link
            invitations.insert(invitation, at: 0)
            shareInvitation(invitation)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func revokeInvitation(_ invitation: HouseholdInvitation) async {
        do {
            try await invitationService.revokeInvitation(invitation.id)
            if let index = invitations.firstIndex(where: { $0.id == invitation.id }) {
                invitations[index].status = .revoked
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func shareInvitation(_ invitation: HouseholdInvitation) {
        guard let url = invitationService.generateInviteLink(for: invitation) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [
                "Join my household on McCall Home!",
                url
            ],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        InvitationsView()
    }
}
