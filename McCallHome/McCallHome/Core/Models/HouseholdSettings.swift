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

    // Week & Grocery Settings
    var weekStartDay: Int  // 0 = Sunday, 1 = Monday, ... 6 = Saturday
    var groceryShoppingDay: Int  // Day of week for grocery shopping (0-6)
    var excludeNonInstacartStores: Bool  // Exclude items marked for non-Instacart stores
    var excludeInPersonItems: Bool  // Exclude items marked for in-person shopping
    var groupGroceryListByStore: Bool  // Group grocery list by store
    var autoCheckInstacartItems: Bool  // Auto-check items when sent to Instacart
    var customFoodLabels: [String]  // User-defined custom food labels

    // Appearance
    var darkMode: AppearanceMode

    let createdAt: Date
    var updatedAt: Date

    /// App appearance mode
    enum AppearanceMode: String, Codable, CaseIterable {
        case system
        case light
        case dark

        var displayName: String {
            rawValue.capitalized
        }
    }

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
        case weekStartDay = "week_start_day"
        case groceryShoppingDay = "grocery_shopping_day"
        case excludeNonInstacartStores = "exclude_non_instacart_stores"
        case excludeInPersonItems = "exclude_in_person_items"
        case groupGroceryListByStore = "group_grocery_list_by_store"
        case autoCheckInstacartItems = "auto_check_instacart_items"
        case customFoodLabels = "custom_food_labels"
        case darkMode = "dark_mode"
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
        weekStartDay: Int = 0,  // Sunday
        groceryShoppingDay: Int = 6,  // Saturday
        excludeNonInstacartStores: Bool = true,
        excludeInPersonItems: Bool = true,
        groupGroceryListByStore: Bool = false,
        autoCheckInstacartItems: Bool = true,
        customFoodLabels: [String] = [],
        darkMode: AppearanceMode = .system,
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
        self.weekStartDay = weekStartDay
        self.groceryShoppingDay = groceryShoppingDay
        self.excludeNonInstacartStores = excludeNonInstacartStores
        self.excludeInPersonItems = excludeInPersonItems
        self.groupGroceryListByStore = groupGroceryListByStore
        self.autoCheckInstacartItems = autoCheckInstacartItems
        self.customFoodLabels = customFoodLabels
        self.darkMode = darkMode
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

        // Week & Grocery Settings
        weekStartDay = try container.decodeIfPresent(Int.self, forKey: .weekStartDay) ?? 0
        groceryShoppingDay = try container.decodeIfPresent(Int.self, forKey: .groceryShoppingDay) ?? 6
        excludeNonInstacartStores = try container.decodeIfPresent(Bool.self, forKey: .excludeNonInstacartStores) ?? true
        excludeInPersonItems = try container.decodeIfPresent(Bool.self, forKey: .excludeInPersonItems) ?? true
        groupGroceryListByStore = try container.decodeIfPresent(Bool.self, forKey: .groupGroceryListByStore) ?? false
        autoCheckInstacartItems = try container.decodeIfPresent(Bool.self, forKey: .autoCheckInstacartItems) ?? true
        customFoodLabels = try container.decodeIfPresent([String].self, forKey: .customFoodLabels) ?? []

        // Appearance
        darkMode = try container.decodeIfPresent(AppearanceMode.self, forKey: .darkMode) ?? .system

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

    /// Get the display name for a weekday index (0 = Sunday, 6 = Saturday)
    static func weekdayName(for index: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard index >= 0 && index < 7 else { return "Unknown" }
        return days[index]
    }

    /// Display name for week start day
    var weekStartDayName: String {
        Self.weekdayName(for: weekStartDay)
    }

    /// Display name for grocery shopping day
    var groceryShoppingDayName: String {
        Self.weekdayName(for: groceryShoppingDay)
    }

    /// Calculate smart default date range for grocery list generation
    /// Returns (startDate, endDate) based on current date and week/grocery settings
    func smartGroceryDateRange(from currentDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        // Get current weekday (1 = Sunday in Calendar, but we use 0 = Sunday)
        let currentWeekday = (calendar.component(.weekday, from: currentDate) - 1)

        // Calculate days since the week started
        var daysSinceWeekStart = currentWeekday - weekStartDay
        if daysSinceWeekStart < 0 {
            daysSinceWeekStart += 7
        }

        // If we're in day 0 or 1 of the current week, use current week
        // Otherwise use next week
        let useNextWeek = daysSinceWeekStart >= 2

        // Calculate the start of the target week
        let currentWeekStart = calendar.date(byAdding: .day, value: -daysSinceWeekStart, to: currentDate)!
        let targetWeekStart: Date

        if useNextWeek {
            targetWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart)!
        } else {
            targetWeekStart = currentWeekStart
        }

        // End date is 6 days after start (full week)
        let targetWeekEnd = calendar.date(byAdding: .day, value: 6, to: targetWeekStart)!

        return (start: calendar.startOfDay(for: targetWeekStart),
                end: calendar.startOfDay(for: targetWeekEnd))
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
