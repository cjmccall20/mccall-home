//
//  IngredientPreferenceService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Supabase

@MainActor
class IngredientPreferenceService {
    static let shared = IngredientPreferenceService()
    private init() {}

    // MARK: - Fetch Operations

    func fetchAllPreferences(for householdId: UUID) async throws -> [IngredientPreference] {
        let response: [IngredientPreference] = try await supabase
            .from("ingredient_preferences")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("canonical_name", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchPreference(for canonicalName: String, householdId: UUID) async throws -> IngredientPreference? {
        let response: [IngredientPreference] = try await supabase
            .from("ingredient_preferences")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("canonical_name", value: canonicalName.lowercased())
            .limit(1)
            .execute()
            .value
        return response.first
    }

    // MARK: - Create/Update Operations

    func createPreference(_ preference: IngredientPreference) async throws {
        try await supabase
            .from("ingredient_preferences")
            .insert(preference)
            .execute()
    }

    func updatePreference(_ preference: IngredientPreference) async throws {
        var updated = preference
        updated.updatedAt = Date()

        try await supabase
            .from("ingredient_preferences")
            .update(updated)
            .eq("id", value: preference.id.uuidString)
            .execute()
    }

    func upsertPreference(_ preference: IngredientPreference) async throws {
        try await supabase
            .from("ingredient_preferences")
            .upsert(preference)
            .execute()
    }

    func deletePreference(_ preferenceId: UUID) async throws {
        try await supabase
            .from("ingredient_preferences")
            .delete()
            .eq("id", value: preferenceId.uuidString)
            .execute()
    }

    // MARK: - Bulk Operations

    /// Ensures ingredient preferences exist for a list of ingredient names
    /// Creates new preferences for any that don't exist yet
    func ensurePreferencesExist(for ingredientNames: [String], householdId: UUID) async throws {
        // Normalize names
        let normalizedNames = ingredientNames.map { normalizeIngredientName($0) }
        let uniqueNames = Array(Set(normalizedNames))

        // Fetch existing preferences
        let existing = try await fetchAllPreferences(for: householdId)
        let existingNames = Set(existing.map { $0.canonicalName })

        // Create preferences for new ingredients
        let newNames = uniqueNames.filter { !existingNames.contains($0) }

        for name in newNames {
            let preference = IngredientPreference(
                householdId: householdId,
                canonicalName: name
            )
            try await createPreference(preference)
        }
    }

    // MARK: - Ingredient Name Normalization

    /// Normalizes an ingredient name to a canonical form
    /// This helps match "all purpose flour" to "flour", "soy sauce" to "soy sauce", etc.
    func normalizeIngredientName(_ name: String) -> String {
        var normalized = name.lowercased().trimmingCharacters(in: .whitespaces)

        // Remove common qualifiers
        let qualifiersToRemove = [
            "fresh ", "dried ", "frozen ", "canned ",
            "organic ", "all-purpose ", "all purpose ",
            "large ", "small ", "medium ",
            "whole ", "chopped ", "diced ", "minced ", "sliced ",
            "boneless ", "skinless ",
            "low-sodium ", "low sodium ", "reduced-sodium ",
            "unsalted ", "salted ",
            "extra-virgin ", "extra virgin ",
            "light ", "dark ",
        ]

        for qualifier in qualifiersToRemove {
            normalized = normalized.replacingOccurrences(of: qualifier, with: "")
        }

        // Trim again after removing qualifiers
        normalized = normalized.trimmingCharacters(in: .whitespaces)

        return normalized
    }

    /// Finds the best matching preference for an ingredient name
    func findMatchingPreference(for ingredientName: String, in preferences: [IngredientPreference]) -> IngredientPreference? {
        let normalized = normalizeIngredientName(ingredientName)

        // First try exact match
        if let exact = preferences.first(where: { $0.canonicalName == normalized }) {
            return exact
        }

        // Then try if normalized name contains or is contained by any canonical name
        for pref in preferences {
            if normalized.contains(pref.canonicalName) || pref.canonicalName.contains(normalized) {
                return pref
            }
        }

        return nil
    }
}
