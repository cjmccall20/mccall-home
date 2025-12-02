//
//  GroceryList.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

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

    init(id: UUID, householdId: UUID, weekStart: Date, isCurrent: Bool, mealPlanHash: String? = nil, generatedAt: Date? = nil) {
        self.id = id
        self.householdId = householdId
        self.weekStart = weekStart
        self.isCurrent = isCurrent
        self.mealPlanHash = mealPlanHash
        self.generatedAt = generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        isCurrent = try container.decodeIfPresent(Bool.self, forKey: .isCurrent) ?? false
        mealPlanHash = try container.decodeIfPresent(String.self, forKey: .mealPlanHash)

        // Handle week_start - can be "YYYY-MM-DD" date string
        if let dateString = try? container.decode(String.self, forKey: .weekStart) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            if let date = formatter.date(from: dateString) {
                weekStart = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                weekStart = date
            } else {
                weekStart = Date()
            }
        } else {
            weekStart = try container.decodeIfPresent(Date.self, forKey: .weekStart) ?? Date()
        }

        // Handle generated_at - ISO8601 timestamp
        if let dateString = try? container.decode(String.self, forKey: .generatedAt) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                generatedAt = date
            } else {
                generatedAt = ISO8601DateFormatter().date(from: dateString)
            }
        } else {
            generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt)
        }
    }
}
