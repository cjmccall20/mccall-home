//
//  RecipeRatingService.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import Foundation
import Supabase

@MainActor
class RecipeRatingService {
    static let shared = RecipeRatingService()
    private init() {}

    // MARK: - Fetch Ratings

    /// Fetch all ratings for a household
    func fetchRatings(for householdId: UUID) async throws -> [RecipeRating] {
        let response: [RecipeRating] = try await supabase
            .from("recipe_ratings")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .execute()
            .value
        return response
    }

    /// Fetch ratings for a specific member
    func fetchRatingsForMember(memberId: UUID, householdId: UUID) async throws -> [RecipeRating] {
        let response: [RecipeRating] = try await supabase
            .from("recipe_ratings")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("member_id", value: memberId.uuidString)
            .execute()
            .value
        return response
    }

    /// Fetch rating for a specific recipe by a specific member
    func fetchRating(recipeId: UUID, memberId: UUID, householdId: UUID) async throws -> RecipeRating? {
        let response: [RecipeRating] = try await supabase
            .from("recipe_ratings")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("member_id", value: memberId.uuidString)
            .eq("recipe_id", value: recipeId.uuidString)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    /// Fetch all ratings for a specific recipe
    func fetchRatingsForRecipe(recipeId: UUID, householdId: UUID) async throws -> [RecipeRating] {
        let response: [RecipeRating] = try await supabase
            .from("recipe_ratings")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .eq("recipe_id", value: recipeId.uuidString)
            .execute()
            .value
        return response
    }

    // MARK: - Create/Update Ratings

    /// Set or update a rating for a recipe
    func setRating(
        recipeId: UUID,
        memberId: UUID,
        householdId: UUID,
        rating: Int?,
        isFavorite: Bool? = nil,
        notes: String? = nil
    ) async throws -> RecipeRating {
        // Check if rating already exists
        if var existing = try await fetchRating(recipeId: recipeId, memberId: memberId, householdId: householdId) {
            // Update existing
            existing.rating = rating ?? existing.rating
            if let fav = isFavorite {
                existing.isFavorite = fav
            }
            existing.notes = notes ?? existing.notes
            existing.updatedAt = Date()

            try await supabase
                .from("recipe_ratings")
                .update(existing)
                .eq("id", value: existing.id.uuidString)
                .execute()

            return existing
        } else {
            // Create new
            let newRating = RecipeRating(
                householdId: householdId,
                memberId: memberId,
                recipeId: recipeId,
                rating: rating,
                isFavorite: isFavorite ?? false,
                notes: notes
            )

            try await supabase
                .from("recipe_ratings")
                .insert(newRating)
                .execute()

            return newRating
        }
    }

    /// Toggle favorite status for a recipe
    func toggleFavorite(
        recipeId: UUID,
        memberId: UUID,
        householdId: UUID
    ) async throws -> RecipeRating {
        if var existing = try await fetchRating(recipeId: recipeId, memberId: memberId, householdId: householdId) {
            existing.isFavorite.toggle()
            existing.updatedAt = Date()

            try await supabase
                .from("recipe_ratings")
                .update(existing)
                .eq("id", value: existing.id.uuidString)
                .execute()

            return existing
        } else {
            // Create new with favorite = true
            let newRating = RecipeRating(
                householdId: householdId,
                memberId: memberId,
                recipeId: recipeId,
                isFavorite: true
            )

            try await supabase
                .from("recipe_ratings")
                .insert(newRating)
                .execute()

            return newRating
        }
    }

    // MARK: - Delete Ratings

    func deleteRating(_ rating: RecipeRating) async throws {
        try await supabase
            .from("recipe_ratings")
            .delete()
            .eq("id", value: rating.id.uuidString)
            .execute()
    }

    // MARK: - Aggregate Functions

    /// Get aggregate rating info for a recipe
    func getAggregate(for recipeId: UUID, ratings: [RecipeRating]) -> RecipeRatingAggregate {
        let recipeRatings = ratings.filter { $0.recipeId == recipeId }

        let validRatings = recipeRatings.compactMap { $0.rating }
        let averageRating: Double? = validRatings.isEmpty ? nil : Double(validRatings.reduce(0, +)) / Double(validRatings.count)
        let favoriteCount = recipeRatings.filter { $0.isFavorite }.count

        return RecipeRatingAggregate(
            recipeId: recipeId,
            averageRating: averageRating,
            ratingCount: validRatings.count,
            favoriteCount: favoriteCount
        )
    }

    /// Get all favorite recipes for a member
    func getFavoriteRecipeIds(memberId: UUID, ratings: [RecipeRating]) -> [UUID] {
        ratings.filter { $0.memberId == memberId && $0.isFavorite }.map { $0.recipeId }
    }

    /// Get member's rating for a recipe
    func getMemberRating(recipeId: UUID, memberId: UUID, ratings: [RecipeRating]) -> RecipeRating? {
        ratings.first { $0.recipeId == recipeId && $0.memberId == memberId }
    }
}
