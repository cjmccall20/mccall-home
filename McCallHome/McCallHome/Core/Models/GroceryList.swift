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
    var isCompleted: Bool      // Whether shopping is complete for this list
    var completedAt: Date?     // When shopping was completed
    var mealPlanHash: String?
    var generatedAt: Date?
    var dateRangeStart: Date?  // Start of the date range this list covers
    var dateRangeEnd: Date?    // End of the date range this list covers

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case weekStart = "week_start"
        case isCurrent = "is_current"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case mealPlanHash = "meal_plan_hash"
        case generatedAt = "generated_at"
        case dateRangeStart = "date_range_start"
        case dateRangeEnd = "date_range_end"
    }

    /// Formatted date range string (e.g., "Nov 30 - Dec 6")
    var formattedDateRange: String? {
        let start = dateRangeStart ?? weekStart
        let end = dateRangeEnd ?? Calendar.current.date(byAdding: .day, value: 6, to: start)
        guard let endDate = end else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: endDate))"
    }

    /// Formatted generation time string
    var formattedGeneratedAt: String? {
        guard let generatedAt = generatedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: generatedAt)
    }

    init(id: UUID, householdId: UUID, weekStart: Date, isCurrent: Bool, isCompleted: Bool = false, completedAt: Date? = nil, mealPlanHash: String? = nil, generatedAt: Date? = nil, dateRangeStart: Date? = nil, dateRangeEnd: Date? = nil) {
        self.id = id
        self.householdId = householdId
        self.weekStart = weekStart
        self.isCurrent = isCurrent
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.mealPlanHash = mealPlanHash
        self.generatedAt = generatedAt
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        isCurrent = try container.decodeIfPresent(Bool.self, forKey: .isCurrent) ?? false
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        mealPlanHash = try container.decodeIfPresent(String.self, forKey: .mealPlanHash)

        // Handle completedAt date - ISO8601 timestamp
        if let dateString = try? container.decode(String.self, forKey: .completedAt) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                completedAt = date
            } else {
                completedAt = ISO8601DateFormatter().date(from: dateString)
            }
        } else {
            completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        // Handle week_start - can be "YYYY-MM-DD" date string
        if let dateString = try? container.decode(String.self, forKey: .weekStart) {
            if let date = dateFormatter.date(from: dateString) {
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

        // Handle date range fields
        if let dateString = try? container.decode(String.self, forKey: .dateRangeStart) {
            dateRangeStart = dateFormatter.date(from: dateString)
        } else {
            dateRangeStart = try container.decodeIfPresent(Date.self, forKey: .dateRangeStart)
        }

        if let dateString = try? container.decode(String.self, forKey: .dateRangeEnd) {
            dateRangeEnd = dateFormatter.date(from: dateString)
        } else {
            dateRangeEnd = try container.decodeIfPresent(Date.self, forKey: .dateRangeEnd)
        }
    }
}
