//
//  MealPlanEntry.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct MealPlanEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    let recipeId: UUID
    var scheduledDate: Date
    var servingsOverride: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case recipeId = "recipe_id"
        case scheduledDate = "scheduled_date"
        case servingsOverride = "servings_override"
        case createdAt = "created_at"
    }
}
