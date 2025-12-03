//
//  HouseholdSettingsService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Supabase

class HouseholdSettingsService {
    static let shared = HouseholdSettingsService()

    private init() {}

    // MARK: - Fetch Settings

    func fetchSettings(for householdId: UUID) async throws -> HouseholdSettings {
        let settings: [HouseholdSettings] = try await supabase
            .from("household_settings")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .limit(1)
            .execute()
            .value

        if let existing = settings.first {
            return existing
        }

        // Settings should auto-create via trigger, but create if missing
        return try await createDefaultSettings(for: householdId)
    }

    // MARK: - Create Default Settings

    private func createDefaultSettings(for householdId: UUID) async throws -> HouseholdSettings {
        let newSettings = HouseholdSettings(householdId: householdId)

        try await supabase
            .from("household_settings")
            .insert(newSettings)
            .execute()

        return newSettings
    }

    // MARK: - Update Settings

    func updateSettings(_ settings: HouseholdSettings) async throws {
        try await supabase
            .from("household_settings")
            .update(settings)
            .eq("id", value: settings.id.uuidString)
            .execute()
    }

    // MARK: - Update Specific Fields

    func updateCalendarSettings(
        for householdId: UUID,
        enabled: Bool,
        calendarId: String?,
        syncMeals: Bool
    ) async throws {
        struct CalendarUpdate: Encodable {
            let google_calendar_enabled: Bool
            let google_calendar_id: String?
            let sync_meals_to_calendar: Bool
        }

        let update = CalendarUpdate(
            google_calendar_enabled: enabled,
            google_calendar_id: calendarId,
            sync_meals_to_calendar: syncMeals
        )

        try await supabase
            .from("household_settings")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    func updateMealTimes(
        for householdId: UUID,
        breakfast: String,
        lunch: String,
        dinner: String
    ) async throws {
        struct MealTimesUpdate: Encodable {
            let breakfast_time: String
            let lunch_time: String
            let dinner_time: String
        }

        let update = MealTimesUpdate(
            breakfast_time: breakfast,
            lunch_time: lunch,
            dinner_time: dinner
        )

        try await supabase
            .from("household_settings")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    func updateEmailSettings(
        for householdId: UUID,
        enabled: Bool,
        time: String,
        recipients: [String]
    ) async throws {
        struct EmailUpdate: Encodable {
            let morning_email_enabled: Bool
            let morning_email_time: String
            let morning_email_recipients: [String]
        }

        let update = EmailUpdate(
            morning_email_enabled: enabled,
            morning_email_time: time,
            morning_email_recipients: recipients
        )

        try await supabase
            .from("household_settings")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    func updateTimezone(for householdId: UUID, timezone: String) async throws {
        struct TimezoneUpdate: Encodable {
            let timezone: String
        }

        try await supabase
            .from("household_settings")
            .update(TimezoneUpdate(timezone: timezone))
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    // MARK: - Store Google OAuth Token

    func storeGoogleRefreshToken(for householdId: UUID, refreshToken: String) async throws {
        struct TokenUpdate: Encodable {
            let google_refresh_token: String
            let google_calendar_enabled: Bool
        }

        let update = TokenUpdate(
            google_refresh_token: refreshToken,
            google_calendar_enabled: true
        )

        try await supabase
            .from("household_settings")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    func clearGoogleCalendar(for householdId: UUID) async throws {
        struct ClearCalendarUpdate: Encodable {
            let google_calendar_enabled: Bool
            let google_calendar_id: String?
            let google_refresh_token: String?
            let sync_meals_to_calendar: Bool
        }

        let update = ClearCalendarUpdate(
            google_calendar_enabled: false,
            google_calendar_id: nil,
            google_refresh_token: nil,
            sync_meals_to_calendar: false
        )

        try await supabase
            .from("household_settings")
            .update(update)
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    // MARK: - Week & Grocery Settings

    func updateWeekSettings(
        for householdId: UUID,
        weekStartDay: Int,
        groceryShoppingDay: Int
    ) async throws {
        struct WeekUpdate: Encodable {
            let week_start_day: Int
            let grocery_shopping_day: Int
        }

        try await supabase
            .from("household_settings")
            .update(WeekUpdate(week_start_day: weekStartDay, grocery_shopping_day: groceryShoppingDay))
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    func updateInstacartSettings(
        for householdId: UUID,
        excludeNonInstacartStores: Bool,
        excludeInPersonItems: Bool,
        groupByStore: Bool
    ) async throws {
        struct InstacartUpdate: Encodable {
            let exclude_non_instacart_stores: Bool
            let exclude_in_person_items: Bool
            let group_grocery_list_by_store: Bool
        }

        try await supabase
            .from("household_settings")
            .update(InstacartUpdate(
                exclude_non_instacart_stores: excludeNonInstacartStores,
                exclude_in_person_items: excludeInPersonItems,
                group_grocery_list_by_store: groupByStore
            ))
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }

    // MARK: - Appearance

    func updateDarkMode(for householdId: UUID, mode: HouseholdSettings.AppearanceMode) async throws {
        struct AppearanceUpdate: Encodable {
            let dark_mode: String
        }

        try await supabase
            .from("household_settings")
            .update(AppearanceUpdate(dark_mode: mode.rawValue))
            .eq("household_id", value: householdId.uuidString)
            .execute()
    }
}
