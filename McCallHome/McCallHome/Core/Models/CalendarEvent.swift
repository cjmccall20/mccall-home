//
//  CalendarEvent.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation

struct CalendarEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var googleEventId: String?
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var allDay: Bool
    let createdBy: UUID?
    var syncedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case googleEventId = "google_event_id"
        case title
        case description
        case startTime = "start_time"
        case endTime = "end_time"
        case allDay = "all_day"
        case createdBy = "created_by"
        case syncedAt = "synced_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
