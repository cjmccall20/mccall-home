//
//  HouseholdMemberService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Supabase

@MainActor
class HouseholdMemberService {
    static let shared = HouseholdMemberService()
    private init() {}

    func fetchMembers(for householdId: UUID) async throws -> [HouseholdMember] {
        let response: [HouseholdMember] = try await supabase
            .from("household_members")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_active", value: true)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    func createMember(name: String, email: String?, householdId: UUID) async throws -> HouseholdMember {
        let member = HouseholdMember(
            householdId: householdId,
            name: name,
            email: email
        )

        let response: [HouseholdMember] = try await supabase
            .from("household_members")
            .insert(member)
            .select()
            .execute()
            .value

        guard let created = response.first else {
            throw HouseholdMemberError.failedToCreate
        }
        return created
    }

    func updateMember(_ member: HouseholdMember) async throws {
        try await supabase
            .from("household_members")
            .update(member)
            .eq("id", value: member.id.uuidString)
            .execute()
    }

    func deleteMember(_ member: HouseholdMember) async throws {
        // Soft delete - just mark as inactive
        try await supabase
            .from("household_members")
            .update(["is_active": false])
            .eq("id", value: member.id.uuidString)
            .execute()
    }

    func hardDeleteMember(_ member: HouseholdMember) async throws {
        try await supabase
            .from("household_members")
            .delete()
            .eq("id", value: member.id.uuidString)
            .execute()
    }

    enum HouseholdMemberError: LocalizedError {
        case failedToCreate

        var errorDescription: String? {
            switch self {
            case .failedToCreate:
                return "Failed to create household member"
            }
        }
    }
}
