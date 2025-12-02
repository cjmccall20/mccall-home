//
//  HouseholdSettings.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation

struct HouseholdSettings: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID

    // Calendar Integration
    var googleCalendarEnabled: Bool
    var googleCalendarId: String?
    var syncMealsToCalendar: Bool

    // Default Meal Times
    var breakfastTime: String
    var lunchTime: String
    var dinnerTime: String

    // Email Preferences
    var morningEmailEnabled: Bool
    var morningEmailTime: String
    var morningEmailRecipients: [String]?

    // Timezone
    var timezone: String

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case googleCalendarEnabled = "google_calendar_enabled"
        case googleCalendarId = "google_calendar_id"
        case syncMealsToCalendar = "sync_meals_to_calendar"
        case breakfastTime = "breakfast_time"
        case lunchTime = "lunch_time"
        case dinnerTime = "dinner_time"
        case morningEmailEnabled = "morning_email_enabled"
        case morningEmailTime = "morning_email_time"
        case morningEmailRecipients = "morning_email_recipients"
        case timezone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        householdId: UUID,
        googleCalendarEnabled: Bool = false,
        googleCalendarId: String? = nil,
        syncMealsToCalendar: Bool = false,
        breakfastTime: String = "08:00",
        lunchTime: String = "12:00",
        dinnerTime: String = "18:00",
        morningEmailEnabled: Bool = false,
        morningEmailTime: String = "07:00",
        morningEmailRecipients: [String]? = nil,
        timezone: String = "America/New_York",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.googleCalendarEnabled = googleCalendarEnabled
        self.googleCalendarId = googleCalendarId
        self.syncMealsToCalendar = syncMealsToCalendar
        self.breakfastTime = breakfastTime
        self.lunchTime = lunchTime
        self.dinnerTime = dinnerTime
        self.morningEmailEnabled = morningEmailEnabled
        self.morningEmailTime = morningEmailTime
        self.morningEmailRecipients = morningEmailRecipients
        self.timezone = timezone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)

        googleCalendarEnabled = try container.decodeIfPresent(Bool.self, forKey: .googleCalendarEnabled) ?? false
        googleCalendarId = try container.decodeIfPresent(String.self, forKey: .googleCalendarId)
        syncMealsToCalendar = try container.decodeIfPresent(Bool.self, forKey: .syncMealsToCalendar) ?? false

        breakfastTime = try container.decodeIfPresent(String.self, forKey: .breakfastTime) ?? "08:00"
        lunchTime = try container.decodeIfPresent(String.self, forKey: .lunchTime) ?? "12:00"
        dinnerTime = try container.decodeIfPresent(String.self, forKey: .dinnerTime) ?? "18:00"

        morningEmailEnabled = try container.decodeIfPresent(Bool.self, forKey: .morningEmailEnabled) ?? false
        morningEmailTime = try container.decodeIfPresent(String.self, forKey: .morningEmailTime) ?? "07:00"
        morningEmailRecipients = try container.decodeIfPresent([String].self, forKey: .morningEmailRecipients)

        timezone = try container.decodeIfPresent(String.self, forKey: .timezone) ?? "America/New_York"

        // Handle dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) ?? Date()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }

        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) ?? Date()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }

    // Helper to get meal time as Date components
    func mealTimeDate(for meal: MealType) -> DateComponents {
        let timeString: String
        switch meal {
        case .breakfast:
            timeString = breakfastTime
        case .lunch:
            timeString = lunchTime
        case .dinner:
            timeString = dinnerTime
        }

        let parts = timeString.split(separator: ":")
        var components = DateComponents()
        if parts.count >= 2 {
            components.hour = Int(parts[0])
            components.minute = Int(parts[1])
        }
        return components
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner

    var displayName: String {
        rawValue.capitalized
    }
}
