//
//  HouseholdMembersView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import Combine

struct HouseholdMembersView: View {
    @StateObject private var viewModel = HouseholdMembersViewModel()
    @State private var showAddMember = false
    @State private var memberToEdit: HouseholdMember?
    @State private var memberToTransfer: HouseholdMember?
    @State private var showTransferConfirmation = false

    var body: some View {
        List {
            Section {
                ForEach(viewModel.members) { member in
                    HStack {
                        Circle()
                            .fill(member.isOwner ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(member.initial)
                                    .font(.headline)
                                    .foregroundStyle(member.isOwner ? .orange : .blue)
                            )

                        VStack(alignment: .leading) {
                            HStack(spacing: 6) {
                                Text(member.name)
                                    .font(.headline)

                                if member.isOwner {
                                    Text("Owner")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                            if let email = member.email, !email.isEmpty {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        memberToEdit = member
                    }
                    .swipeActions(edge: .trailing) {
                        // Only allow deletion if not owner
                        if !member.isOwner {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteMember(member)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        // Allow transfer ownership if current user is owner and this isn't the owner
                        if viewModel.currentUserIsOwner && !member.isOwner {
                            Button {
                                memberToTransfer = member
                                showTransferConfirmation = true
                            } label: {
                                Label("Make Owner", systemImage: "crown")
                            }
                            .tint(.orange)
                        }
                    }
                }
            } header: {
                Text("Members")
            } footer: {
                if viewModel.currentUserIsOwner {
                    Text("Swipe left to delete members. Swipe right to transfer ownership.")
                } else {
                    Text("Household members can be assigned to tasks and restaurant orders.")
                }
            }
        }
        .navigationTitle("Household")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddMember = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.fetchMembers()
        }
        .sheet(isPresented: $showAddMember) {
            AddEditMemberView(viewModel: viewModel, member: nil) {
                showAddMember = false
            }
        }
        .sheet(item: $memberToEdit) { member in
            AddEditMemberView(viewModel: viewModel, member: member) {
                memberToEdit = nil
            }
        }
        .confirmationDialog("Transfer Ownership", isPresented: $showTransferConfirmation, presenting: memberToTransfer) { member in
            Button("Transfer to \(member.name)", role: .destructive) {
                Task {
                    await viewModel.transferOwnership(to: member)
                }
            }
        } message: { member in
            Text("Are you sure you want to make \(member.name) the household owner? You will no longer be able to delete accounts or transfer ownership.")
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

// MARK: - Add/Edit Member View

struct AddEditMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HouseholdMembersViewModel
    let member: HouseholdMember?
    let onComplete: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var isSaving = false

    var isEditing: Bool {
        member != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle(isEditing ? "Edit Member" : "Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let member = member {
                    name = member.name
                    email = member.email ?? ""
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        if let existingMember = member {
            var updated = existingMember
            updated.name = name
            updated.email = email.isEmpty ? nil : email
            await viewModel.updateMember(updated)
        } else {
            await viewModel.addMember(name: name, email: email.isEmpty ? nil : email)
        }

        dismiss()
        onComplete()
    }
}

// MARK: - ViewModel

@MainActor
class HouseholdMembersViewModel: ObservableObject {
    @Published var members: [HouseholdMember] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = HouseholdMemberService.shared
    private let authService = AuthService.shared

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    var currentUserIsOwner: Bool {
        // In dev mode, always return true for testing
        if Config.skipAuthForDevelopment {
            return true
        }
        // Check if current user matches an owner member
        guard let currentUserName = authService.currentUser?.name else { return false }
        return members.first { $0.name == currentUserName }?.isOwner ?? false
    }

    var ownerMember: HouseholdMember? {
        members.first { $0.isOwner }
    }

    func fetchMembers() async {
        guard let householdId = householdId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            members = try await service.fetchMembers(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addMember(name: String, email: String?) async {
        guard let householdId = householdId else { return }

        do {
            let member = try await service.createMember(name: name, email: email, householdId: householdId)
            members.append(member)
            members.sort { $0.name < $1.name }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateMember(_ member: HouseholdMember) async {
        do {
            try await service.updateMember(member)
            if let index = members.firstIndex(where: { $0.id == member.id }) {
                members[index] = member
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteMember(_ member: HouseholdMember) async {
        // Prevent deleting the owner
        guard !member.isOwner else {
            self.error = "Cannot delete the household owner"
            return
        }

        do {
            try await service.deleteMember(member)
            members.removeAll { $0.id == member.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func transferOwnership(to newOwner: HouseholdMember) async {
        guard let householdId = householdId else { return }

        do {
            try await service.transferOwnership(to: newOwner.id, householdId: householdId)

            // Update local state
            for i in members.indices {
                members[i].isOwner = (members[i].id == newOwner.id)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        HouseholdMembersView()
    }
}
