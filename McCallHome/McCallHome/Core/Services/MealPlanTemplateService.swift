//
//  MealPlanTemplateService.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import Foundation
import Supabase

@MainActor
class MealPlanTemplateService {
    static let shared = MealPlanTemplateService()
    private init() {}

    private let mealPlanService = MealPlanService.shared

    // MARK: - Template CRUD

    func fetchTemplates(for householdId: UUID) async throws -> [MealPlanTemplate] {
        let response: [MealPlanTemplate] = try await supabase
            .from("meal_plan_templates")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchTemplate(id: UUID) async throws -> MealPlanTemplate? {
        let response: [MealPlanTemplate] = try await supabase
            .from("meal_plan_templates")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func createTemplate(_ template: MealPlanTemplate) async throws {
        try await supabase
            .from("meal_plan_templates")
            .insert(template)
            .execute()
    }

    func updateTemplate(_ template: MealPlanTemplate) async throws {
        var updated = template
        updated.updatedAt = Date()
        try await supabase
            .from("meal_plan_templates")
            .update(updated)
            .eq("id", value: template.id.uuidString)
            .execute()
    }

    func deleteTemplate(_ template: MealPlanTemplate) async throws {
        try await supabase
            .from("meal_plan_templates")
            .delete()
            .eq("id", value: template.id.uuidString)
            .execute()
    }

    /// Duplicate a template with a new name
    func copyTemplate(_ template: MealPlanTemplate, newName: String) async throws -> MealPlanTemplate {
        let copy = MealPlanTemplate(
            id: UUID(),
            householdId: template.householdId,
            name: newName,
            entries: template.entries,
            isRotating: false,  // Don't copy rotation status
            rotationOrder: nil,
            notes: template.notes,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await createTemplate(copy)
        return copy
    }

    // MARK: - Template Operations

    /// Save the current week as a template
    func saveCurrentWeekAsTemplate(
        name: String,
        weekStart: Date,
        householdId: UUID
    ) async throws -> MealPlanTemplate {
        // Fetch the current week's entries
        let entries = try await mealPlanService.fetchMealPlan(for: householdId, weekStart: weekStart)

        // Create the template
        let template = MealPlanTemplate.from(
            entries: entries,
            weekStart: weekStart,
            name: name,
            householdId: householdId
        )

        // Save to database
        try await createTemplate(template)

        return template
    }

    /// Apply a template to a specific week (creates meal plan entries)
    func applyTemplate(
        _ template: MealPlanTemplate,
        to weekStart: Date,
        householdId: UUID,
        clearExisting: Bool = false
    ) async throws {
        // Optionally clear existing entries for the week
        if clearExisting {
            let existingEntries = try await mealPlanService.fetchMealPlan(for: householdId, weekStart: weekStart)
            for entry in existingEntries {
                try await mealPlanService.removeFromPlan(entryId: entry.id)
            }
        }

        // Create entries from template
        let newEntries = template.apply(to: weekStart, householdId: householdId)

        // Insert all entries
        for entry in newEntries {
            try await supabase
                .from("meal_plan_entries")
                .insert(entry)
                .execute()
        }
    }

    // MARK: - Rotation CRUD

    func fetchRotations(for householdId: UUID) async throws -> [MealPlanRotation] {
        let response: [MealPlanRotation] = try await supabase
            .from("meal_plan_rotations")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    func createRotation(_ rotation: MealPlanRotation) async throws {
        try await supabase
            .from("meal_plan_rotations")
            .insert(rotation)
            .execute()
    }

    func updateRotation(_ rotation: MealPlanRotation) async throws {
        var updated = rotation
        updated.updatedAt = Date()
        try await supabase
            .from("meal_plan_rotations")
            .update(updated)
            .eq("id", value: rotation.id.uuidString)
            .execute()
    }

    func deleteRotation(_ rotation: MealPlanRotation) async throws {
        try await supabase
            .from("meal_plan_rotations")
            .delete()
            .eq("id", value: rotation.id.uuidString)
            .execute()
    }

    /// Advance the rotation to the next template and apply it to the given week
    func advanceAndApplyRotation(
        _ rotation: inout MealPlanRotation,
        to weekStart: Date,
        templates: [MealPlanTemplate],
        householdId: UUID,
        clearExisting: Bool = true
    ) async throws {
        guard let currentTemplateId = rotation.currentTemplateId,
              let template = templates.first(where: { $0.id == currentTemplateId }) else {
            return
        }

        // Apply the current template
        try await applyTemplate(template, to: weekStart, householdId: householdId, clearExisting: clearExisting)

        // Advance to next
        rotation.advance()
        try await updateRotation(rotation)
    }
}
