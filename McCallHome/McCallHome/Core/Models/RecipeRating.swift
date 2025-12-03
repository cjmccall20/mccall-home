//
//  RecipeRating.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import Foundation

/// User-specific rating and favorite status for a recipe
struct RecipeRating: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let memberId: UUID  // Which household member rated this
    let recipeId: UUID
    var rating: Int?  // 1-5 stars, nil if not rated
    var isFavorite: Bool
    var notes: String?  // Personal notes about the recipe
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case memberId = "member_id"
        case recipeId = "recipe_id"
        case rating
        case isFavorite = "is_favorite"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        memberId: UUID,
        recipeId: UUID,
        rating: Int? = nil,
        isFavorite: Bool = false,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.memberId = memberId
        self.recipeId = recipeId
        self.rating = rating
        self.isFavorite = isFavorite
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        memberId = try container.decode(UUID.self, forKey: .memberId)
        recipeId = try container.decode(UUID.self, forKey: .recipeId)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Handle dates
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            if let date = isoFormatter.date(from: dateString) {
                createdAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                createdAt = date
            } else {
                createdAt = Date()
            }
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }

        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            if let date = isoFormatter.date(from: dateString) {
                updatedAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                updatedAt = date
            } else {
                updatedAt = Date()
            }
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }
}

/// Aggregate rating information for a recipe (across all household members)
struct RecipeRatingAggregate: Equatable {
    let recipeId: UUID
    let averageRating: Double?
    let ratingCount: Int
    let favoriteCount: Int

    /// Display string for average rating
    var displayRating: String? {
        guard let avg = averageRating else { return nil }
        return String(format: "%.1f", avg)
    }

    /// Whether this recipe is a household favorite (at least one member has it favorited)
    var isHouseholdFavorite: Bool {
        favoriteCount > 0
    }
}
