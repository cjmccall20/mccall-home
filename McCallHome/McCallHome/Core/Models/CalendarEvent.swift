//
//  CalendarEvent.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

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

    init(id: UUID = UUID(), householdId: UUID, googleEventId: String? = nil, title: String, description: String? = nil, startTime: Date, endTime: Date, allDay: Bool = false, createdBy: UUID? = nil, syncedAt: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.googleEventId = googleEventId
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.allDay = allDay
        self.createdBy = createdBy
        self.syncedAt = syncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        googleEventId = try container.decodeIfPresent(String.self, forKey: .googleEventId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        allDay = try container.decodeIfPresent(Bool.self, forKey: .allDay) ?? false
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Handle startTime
        if let dateString = try? container.decode(String.self, forKey: .startTime) {
            if let date = isoFormatter.date(from: dateString) {
                startTime = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                startTime = date
            } else {
                startTime = Date()
            }
        } else {
            startTime = try container.decodeIfPresent(Date.self, forKey: .startTime) ?? Date()
        }

        // Handle endTime
        if let dateString = try? container.decode(String.self, forKey: .endTime) {
            if let date = isoFormatter.date(from: dateString) {
                endTime = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                endTime = date
            } else {
                endTime = Date()
            }
        } else {
            endTime = try container.decodeIfPresent(Date.self, forKey: .endTime) ?? Date()
        }

        // Handle syncedAt
        if let dateString = try? container.decode(String.self, forKey: .syncedAt) {
            if let date = isoFormatter.date(from: dateString) {
                syncedAt = date
            } else if let date = ISO8601DateFormatter().date(from: dateString) {
                syncedAt = date
            } else {
                syncedAt = nil
            }
        } else {
            syncedAt = try container.decodeIfPresent(Date.self, forKey: .syncedAt)
        }

        // Handle createdAt
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

        // Handle updatedAt
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
