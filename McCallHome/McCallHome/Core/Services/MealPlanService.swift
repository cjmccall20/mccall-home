//
//  MealPlanService.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Supabase

@MainActor
class MealPlanService {
    static let shared = MealPlanService()
    private init() {}

    func fetchMealPlan(for householdId: UUID, weekStart: Date) async throws -> [MealPlanEntry] {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

        let response: [MealPlanEntry] = try await supabase
            .from("meal_plan")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .gte("scheduled_date", value: weekStart.ISO8601Format())
            .lt("scheduled_date", value: weekEnd.ISO8601Format())
            .order("scheduled_date", ascending: true)
            .execute()
            .value
        return response
    }

    func assignRecipe(recipeId: UUID, to date: Date, householdId: UUID, servingsOverride: Int? = nil) async throws {
        let entry = MealPlanEntry(
            id: UUID(),
            householdId: householdId,
            recipeId: recipeId,
            scheduledDate: date,
            servingsOverride: servingsOverride,
            createdAt: Date()
        )

        try await supabase
            .from("meal_plan")
            .insert(entry)
            .execute()
    }

    func removeFromPlan(entryId: UUID) async throws {
        try await supabase
            .from("meal_plan")
            .delete()
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    func updateEntry(_ entry: MealPlanEntry) async throws {
        try await supabase
            .from("meal_plan")
            .update(entry)
            .eq("id", value: entry.id.uuidString)
            .execute()
    }
}
