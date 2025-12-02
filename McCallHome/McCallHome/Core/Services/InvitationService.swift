//
//  InvitationService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Supabase

class InvitationService {
    static let shared = InvitationService()

    private init() {}

    // MARK: - Create Invitation

    func createInvitation(email: String, householdId: UUID, invitedBy: UUID) async throws -> HouseholdInvitation {
        // Check if there's already a pending invitation for this email
        let existing: [HouseholdInvitation] = try await supabase
            .from("household_invitations")
            .select()
            .eq("email", value: email.lowercased())
            .eq("household_id", value: householdId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value

        if let existingInvitation = existing.first {
            // Return existing pending invitation
            return existingInvitation
        }

        // Create new invitation
        let invitation = HouseholdInvitation(
            householdId: householdId,
            email: email.lowercased(),
            invitedBy: invitedBy
        )

        // Insert and get back with server-generated token
        let created: [HouseholdInvitation] = try await supabase
            .from("household_invitations")
            .insert([
                "household_id": householdId.uuidString,
                "email": email.lowercased(),
                "invited_by": invitedBy.uuidString
            ])
            .select()
            .execute()
            .value

        guard let newInvitation = created.first else {
            throw InvitationError.createFailed
        }

        return newInvitation
    }

    // MARK: - Fetch Invitations

    func fetchInvitations(for householdId: UUID) async throws -> [HouseholdInvitation] {
        let invitations: [HouseholdInvitation] = try await supabase
            .from("household_invitations")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return invitations
    }

    func fetchPendingInvitations(for householdId: UUID) async throws -> [HouseholdInvitation] {
        let invitations: [HouseholdInvitation] = try await supabase
            .from("household_invitations")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        return invitations
    }

    // MARK: - Revoke Invitation

    func revokeInvitation(_ invitationId: UUID) async throws {
        try await supabase
            .from("household_invitations")
            .update(["status": "revoked"])
            .eq("id", value: invitationId.uuidString)
            .execute()
    }

    // MARK: - Get Invitation by Token (Public)

    func getInvitationDetails(token: String) async throws -> InvitationDetails {
        let result: InvitationDetails = try await supabase
            .rpc("get_invitation_by_token", params: ["invitation_token": token])
            .execute()
            .value

        return result
    }

    // MARK: - Accept Invitation

    func acceptInvitation(token: String, userId: UUID) async throws -> AcceptInvitationResult {
        let result: AcceptInvitationResult = try await supabase
            .rpc("accept_invitation", params: [
                "invitation_token": token,
                "accepting_user_id": userId.uuidString
            ])
            .execute()
            .value

        return result
    }

    // MARK: - Generate Invite Link

    func generateInviteLink(for invitation: HouseholdInvitation) -> URL? {
        // Deep link format: mccallhome://invite?token=xxx
        var components = URLComponents()
        components.scheme = "mccallhome"
        components.host = "invite"
        components.queryItems = [
            URLQueryItem(name: "token", value: invitation.token)
        ]
        return components.url
    }

    // MARK: - Errors

    enum InvitationError: LocalizedError {
        case createFailed
        case invalidToken
        case expired
        case alreadyAccepted

        var errorDescription: String? {
            switch self {
            case .createFailed:
                return "Failed to create invitation"
            case .invalidToken:
                return "Invalid invitation link"
            case .expired:
                return "This invitation has expired"
            case .alreadyAccepted:
                return "This invitation has already been accepted"
            }
        }
    }
}
