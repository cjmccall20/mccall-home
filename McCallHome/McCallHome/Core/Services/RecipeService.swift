//
//  RecipeService.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Supabase

@MainActor
class RecipeService {
    static let shared = RecipeService()
    private init() {}

    func fetchRecipes(for householdId: UUID) async throws -> [Recipe] {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("title", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchRecipe(by id: UUID) async throws -> Recipe? {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func createRecipe(_ recipe: Recipe) async throws {
        try await supabase
            .from("recipes")
            .insert(recipe)
            .execute()
    }

    func updateRecipe(_ recipe: Recipe) async throws {
        try await supabase
            .from("recipes")
            .update(recipe)
            .eq("id", value: recipe.id.uuidString)
            .execute()
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        try await supabase
            .from("recipes")
            .delete()
            .eq("id", value: recipe.id.uuidString)
            .execute()
    }

    func searchRecipes(query: String, in householdId: UUID) async throws -> [Recipe] {
        let response: [Recipe] = try await supabase
            .from("recipes")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .ilike("title", pattern: "%\(query)%")
            .execute()
            .value
        return response
    }
}
