//
//  HouseStapleService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Supabase

class HouseStapleService {
    static let shared = HouseStapleService()

    private init() {}

    // MARK: - Fetch Staples

    func fetchStaples(for householdId: UUID) async throws -> [HouseStaple] {
        let staples: [HouseStaple] = try await supabase
            .from("house_staples")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("category")
            .order("name")
            .execute()
            .value

        return staples
    }

    func fetchActiveStaples(for householdId: UUID) async throws -> [HouseStaple] {
        let staples: [HouseStaple] = try await supabase
            .from("house_staples")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("is_active", value: true)
            .order("category")
            .order("name")
            .execute()
            .value

        return staples
    }

    // MARK: - Create Staple

    func createStaple(_ staple: HouseStaple) async throws -> HouseStaple {
        struct CreateStaple: Encodable {
            let household_id: String
            let name: String
            let quantity: String?
            let category: String
            let notes: String?
            let is_active: Bool
        }

        let create = CreateStaple(
            household_id: staple.householdId.uuidString,
            name: staple.name,
            quantity: staple.quantity,
            category: staple.category,
            notes: staple.notes,
            is_active: staple.isActive
        )

        let result: [HouseStaple] = try await supabase
            .from("house_staples")
            .insert(create)
            .select()
            .execute()
            .value

        guard let created = result.first else {
            throw NSError(domain: "HouseStapleService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create staple"])
        }

        return created
    }

    // MARK: - Update Staple

    func updateStaple(_ staple: HouseStaple) async throws {
        struct UpdateStaple: Encodable {
            let name: String
            let quantity: String?
            let category: String
            let notes: String?
            let is_active: Bool
        }

        let update = UpdateStaple(
            name: staple.name,
            quantity: staple.quantity,
            category: staple.category,
            notes: staple.notes,
            is_active: staple.isActive
        )

        try await supabase
            .from("house_staples")
            .update(update)
            .eq("id", value: staple.id.uuidString)
            .execute()
    }

    // MARK: - Toggle Active

    func toggleActive(_ staple: HouseStaple) async throws {
        struct ToggleUpdate: Encodable {
            let is_active: Bool
        }

        try await supabase
            .from("house_staples")
            .update(ToggleUpdate(is_active: !staple.isActive))
            .eq("id", value: staple.id.uuidString)
            .execute()
    }

    // MARK: - Delete Staple

    func deleteStaple(_ id: UUID) async throws {
        try await supabase
            .from("house_staples")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
