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

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    func fetchMealPlan(for householdId: UUID, weekStart: Date) async throws -> [MealPlanEntry] {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

        let startStr = dateFormatter.string(from: weekStart)
        let endStr = dateFormatter.string(from: weekEnd)

        let response: [MealPlanEntry] = try await supabase
            .from("meal_plan_entries")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .gte("date", value: startStr)
            .lt("date", value: endStr)
            .order("date", ascending: true)
            .order("meal_type", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchMealPlanForDateRange(for householdId: UUID, startDate: Date, endDate: Date) async throws -> [MealPlanEntry] {
        let startStr = dateFormatter.string(from: startDate)
        // Add 1 day to endDate to include it in the range
        let endDatePlusOne = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        let endStr = dateFormatter.string(from: endDatePlusOne)

        let response: [MealPlanEntry] = try await supabase
            .from("meal_plan_entries")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .gte("date", value: startStr)
            .lt("date", value: endStr)
            .order("date", ascending: true)
            .order("meal_type", ascending: true)
            .execute()
            .value
        return response
    }

    func assignRecipe(recipeId: UUID, to date: Date, mealType: MealPlanEntry.MealType, householdId: UUID, servingsOverride: Int? = nil) async throws {
        let entry = MealPlanEntry(
            id: UUID(),
            householdId: householdId,
            recipeId: recipeId,
            scheduledDate: date,
            mealType: mealType,
            servingsOverride: servingsOverride,
            isEatOut: false,
            eatOutLocation: nil,
            restaurantId: nil,
            orderIds: [],
            isLeftovers: false,
            leftoversNote: nil,
            createdAt: Date()
        )

        try await supabase
            .from("meal_plan_entries")
            .insert(entry)
            .execute()
    }

    func addEatOut(to date: Date, mealType: MealPlanEntry.MealType, location: String?, householdId: UUID) async throws {
        let entry = MealPlanEntry(
            id: UUID(),
            householdId: householdId,
            recipeId: nil,
            scheduledDate: date,
            mealType: mealType,
            servingsOverride: nil,
            isEatOut: true,
            eatOutLocation: location,
            restaurantId: nil,
            orderIds: [],
            isLeftovers: false,
            leftoversNote: nil,
            createdAt: Date()
        )

        try await supabase
            .from("meal_plan_entries")
            .insert(entry)
            .execute()
    }

    func addEatOutWithRestaurant(to date: Date, mealType: MealPlanEntry.MealType, restaurantId: UUID, orderIds: [UUID], note: String?, householdId: UUID) async throws {
        let entry = MealPlanEntry(
            id: UUID(),
            householdId: householdId,
            recipeId: nil,
            scheduledDate: date,
            mealType: mealType,
            servingsOverride: nil,
            isEatOut: true,
            eatOutLocation: note,
            restaurantId: restaurantId,
            orderIds: orderIds,
            isLeftovers: false,
            leftoversNote: nil,
            createdAt: Date()
        )

        try await supabase
            .from("meal_plan_entries")
            .insert(entry)
            .execute()
    }

    func addLeftovers(to date: Date, mealType: MealPlanEntry.MealType, note: String?, householdId: UUID) async throws {
        let entry = MealPlanEntry(
            id: UUID(),
            householdId: householdId,
            recipeId: nil,
            scheduledDate: date,
            mealType: mealType,
            servingsOverride: nil,
            isEatOut: false,
            eatOutLocation: nil,
            restaurantId: nil,
            orderIds: [],
            isLeftovers: true,
            leftoversNote: note,
            createdAt: Date()
        )

        try await supabase
            .from("meal_plan_entries")
            .insert(entry)
            .execute()
    }

    func removeFromPlan(entryId: UUID) async throws {
        try await supabase
            .from("meal_plan_entries")
            .delete()
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    func updateEntry(_ entry: MealPlanEntry) async throws {
        try await supabase
            .from("meal_plan_entries")
            .update(entry)
            .eq("id", value: entry.id.uuidString)
            .execute()
    }

    func updateServings(entryId: UUID, servings: Int?) async throws {
        struct ServingsUpdate: Encodable {
            let servings_override: Int?
        }
        try await supabase
            .from("meal_plan_entries")
            .update(ServingsUpdate(servings_override: servings))
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    func updateAssignment(entryId: UUID, assignedTo: UUID?) async throws {
        struct AssignmentUpdate: Encodable {
            let assigned_to: UUID?
        }
        try await supabase
            .from("meal_plan_entries")
            .update(AssignmentUpdate(assigned_to: assignedTo))
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    func entriesForDate(_ date: Date, in entries: [MealPlanEntry]) -> [MealPlanEntry] {
        entries.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
            .sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
    }

    func entry(for date: Date, mealType: MealPlanEntry.MealType, in entries: [MealPlanEntry]) -> MealPlanEntry? {
        entries.first {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) && $0.mealType == mealType
        }
    }

    /// Get all entries for a specific date and meal type (supports multiple dishes per slot)
    func entries(for date: Date, mealType: MealPlanEntry.MealType, in entries: [MealPlanEntry]) -> [MealPlanEntry] {
        entries.filter {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) && $0.mealType == mealType
        }
    }
}
