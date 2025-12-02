//
//  GoogleCalendarService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import Combine
import AuthenticationServices

/// Service for Google Calendar integration
/// Note: Requires GoogleSignIn SDK to be added via Swift Package Manager
/// Add: https://github.com/google/GoogleSignIn-iOS
class GoogleCalendarService: NSObject, ObservableObject {
    static let shared = GoogleCalendarService()

    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var calendars: [GoogleCalendar] = []

    private let clientId = "243332420634-da474f55hp2hn68vkbvfbnjg9r0is1j2.apps.googleusercontent.com"
    private let scopes = [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/calendar.events"
    ]

    private var accessToken: String?
    private var refreshToken: String?

    private let settingsService = HouseholdSettingsService.shared
    private let authService = AuthService.shared

    private override init() {
        super.init()
    }

    // MARK: - Sign In

    /// Start the Google Sign-In flow
    /// This will be called from HouseholdSettingsView when user taps "Connect Google Calendar"
    func signIn() async throws {
        // TODO: Implement with GoogleSignIn SDK once added
        // 1. Present sign-in UI
        // 2. Request calendar scopes
        // 3. Store tokens
        // 4. Update household settings

        // Placeholder implementation for now
        throw GoogleCalendarError.sdkNotConfigured
    }

    /// Sign out and disconnect calendar
    func signOut() async throws {
        guard let householdId = authService.currentUser?.householdId else { return }

        try await settingsService.clearGoogleCalendar(for: householdId)
        isSignedIn = false
        userEmail = nil
        accessToken = nil
        refreshToken = nil
        calendars = []
    }

    // MARK: - Calendar List

    /// Fetch user's calendars
    func fetchCalendars() async throws -> [GoogleCalendar] {
        guard let accessToken = accessToken else {
            throw GoogleCalendarError.notSignedIn
        }

        let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.apiError("Failed to fetch calendars")
        }

        let result = try JSONDecoder().decode(CalendarListResponse.self, from: data)
        calendars = result.items
        return result.items
    }

    // MARK: - Events

    /// Create a calendar event for a meal
    func createMealEvent(
        calendarId: String,
        title: String,
        date: Date,
        mealTime: String, // "HH:mm" format
        duration: Int = 60 // minutes
    ) async throws -> String {
        guard let accessToken = accessToken else {
            throw GoogleCalendarError.notSignedIn
        }

        // Parse meal time and create start/end dates
        let timeParts = mealTime.split(separator: ":")
        guard timeParts.count == 2,
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else {
            throw GoogleCalendarError.invalidTime
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startComponents.hour = hour
        startComponents.minute = minute

        guard let startDate = calendar.date(from: startComponents) else {
            throw GoogleCalendarError.invalidTime
        }

        let endDate = calendar.date(byAdding: .minute, value: duration, to: startDate)!

        let event = GoogleCalendarEvent(
            summary: title,
            start: EventDateTime(dateTime: ISO8601DateFormatter().string(from: startDate)),
            end: EventDateTime(dateTime: ISO8601DateFormatter().string(from: endDate))
        )

        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(event)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.apiError("Failed to create event")
        }

        let createdEvent = try JSONDecoder().decode(GoogleCalendarEventResponse.self, from: data)
        return createdEvent.id
    }

    /// Delete a calendar event
    func deleteEvent(calendarId: String, eventId: String) async throws {
        guard let accessToken = accessToken else {
            throw GoogleCalendarError.notSignedIn
        }

        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events/\(eventId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.apiError("Failed to delete event")
        }
    }

    /// Fetch events for a date range
    func fetchEvents(
        calendarId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [GoogleCalendarEventResponse] {
        guard let accessToken = accessToken else {
            throw GoogleCalendarError.notSignedIn
        }

        let formatter = ISO8601DateFormatter()
        let timeMin = formatter.string(from: startDate)
        let timeMax = formatter.string(from: endDate)

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.apiError("Failed to fetch events")
        }

        let result = try JSONDecoder().decode(EventListResponse.self, from: data)
        return result.items
    }

    // MARK: - Token Management

    /// Refresh the access token using the stored refresh token
    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw GoogleCalendarError.notSignedIn
        }

        // TODO: Implement token refresh with GoogleSignIn SDK
        // For now, throw error to trigger re-authentication
        throw GoogleCalendarError.tokenExpired
    }
}

// MARK: - Error Types

enum GoogleCalendarError: LocalizedError {
    case sdkNotConfigured
    case notSignedIn
    case tokenExpired
    case invalidTime
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .sdkNotConfigured:
            return "Google Sign-In SDK is not yet configured. Please add the GoogleSignIn-iOS package."
        case .notSignedIn:
            return "Not signed in to Google"
        case .tokenExpired:
            return "Session expired. Please sign in again."
        case .invalidTime:
            return "Invalid meal time format"
        case .apiError(let message):
            return message
        }
    }
}

// MARK: - API Models

struct GoogleCalendar: Codable, Identifiable {
    let id: String
    let summary: String
    let primary: Bool?
    let backgroundColor: String?
}

struct CalendarListResponse: Codable {
    let items: [GoogleCalendar]
}

struct GoogleCalendarEvent: Codable {
    let summary: String
    let start: EventDateTime
    let end: EventDateTime
    var description: String?
}

struct EventDateTime: Codable {
    let dateTime: String
    var timeZone: String?
}

struct GoogleCalendarEventResponse: Codable, Identifiable {
    let id: String
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
}

struct EventListResponse: Codable {
    let items: [GoogleCalendarEventResponse]
}
