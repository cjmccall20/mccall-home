//
//  GroceryList.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct GroceryList: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var weekStart: Date
    var isCurrent: Bool
    var mealPlanHash: String?
    var generatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case weekStart = "week_start"
        case isCurrent = "is_current"
        case mealPlanHash = "meal_plan_hash"
        case generatedAt = "generated_at"
    }
}
