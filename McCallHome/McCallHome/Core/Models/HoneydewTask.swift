//
//  HoneydewTask.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine
import SwiftUI

struct HoneydewTask: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var dueTime: String?  // HH:mm format
    var priority: Priority
    var assignedTo: UUID?
    var createdBy: UUID?  // Nullable for dev mode / system-created tasks
    var isComplete: Bool
    var completedAt: Date?
    var recurrenceRule: RecurrenceRule?
    var reminderMinutesBefore: Int?
    var nextOccurrence: Date?
    let createdAt: Date
    var updatedAt: Date

    enum Priority: String, Codable, CaseIterable {
        case low, medium, high, urgent

        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }

        var displayName: String {
            rawValue.capitalized
        }
    }

    struct RecurrenceRule: Codable, Equatable {
        var type: RecurrenceType
        var dayOfWeek: Int?      // 0 = Sunday, 6 = Saturday
        var dayOfMonth: Int?     // 1-31

        enum RecurrenceType: String, Codable, CaseIterable {
            case daily
            case weekly
            case monthly

            var displayName: String {
                switch self {
                case .daily: return "Every Day"
                case .weekly: return "Every Week"
                case .monthly: return "Every Month"
                }
            }
        }

        enum CodingKeys: String, CodingKey {
            case type
            case dayOfWeek = "day_of_week"
            case dayOfMonth = "day_of_month"
        }

        var displayText: String {
            switch type {
            case .daily:
                return "Repeats daily"
            case .weekly:
                if let day = dayOfWeek {
                    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                    return "Repeats every \(weekdays[day])"
                }
                return "Repeats weekly"
            case .monthly:
                if let day = dayOfMonth {
                    return "Repeats on the \(ordinal(day)) of each month"
                }
                return "Repeats monthly"
            }
        }

        private func ordinal(_ n: Int) -> String {
            let suffix: String
            switch n {
            case 1, 21, 31: suffix = "st"
            case 2, 22: suffix = "nd"
            case 3, 23: suffix = "rd"
            default: suffix = "th"
            }
            return "\(n)\(suffix)"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case title
        case description
        case dueDate = "due_date"
        case dueTime = "due_time"
        case priority
        case assignedTo = "assigned_to"
        case createdBy = "created_by"
        case isComplete = "is_complete"
        case completedAt = "completed_at"
        case recurrenceRule = "recurrence_rule"
        case reminderMinutesBefore = "reminder_minutes_before"
        case nextOccurrence = "next_occurrence"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, householdId: UUID, title: String, description: String? = nil, dueDate: Date? = nil, dueTime: String? = nil, priority: Priority = .medium, assignedTo: UUID? = nil, createdBy: UUID? = nil, isComplete: Bool = false, completedAt: Date? = nil, recurrenceRule: RecurrenceRule? = nil, reminderMinutesBefore: Int? = nil, nextOccurrence: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.householdId = householdId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.priority = priority
        self.assignedTo = assignedTo
        self.createdBy = createdBy
        self.isComplete = isComplete
        self.completedAt = completedAt
        self.recurrenceRule = recurrenceRule
        self.reminderMinutesBefore = reminderMinutesBefore
        self.nextOccurrence = nextOccurrence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Handle due date - could be date string or full timestamp
        if let dateString = try? container.decode(String.self, forKey: .dueDate) {
            dueDate = Self.parseDate(dateString)
        } else {
            dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        }

        dueTime = try container.decodeIfPresent(String.self, forKey: .dueTime)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .medium
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false

        // Handle completedAt date
        if let dateString = try? container.decode(String.self, forKey: .completedAt) {
            completedAt = Self.parseDate(dateString)
        } else {
            completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        }

        recurrenceRule = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrenceRule)
        reminderMinutesBefore = try container.decodeIfPresent(Int.self, forKey: .reminderMinutesBefore)

        // Handle nextOccurrence date
        if let dateString = try? container.decode(String.self, forKey: .nextOccurrence) {
            nextOccurrence = Self.parseDate(dateString)
        } else {
            nextOccurrence = try container.decodeIfPresent(Date.self, forKey: .nextOccurrence)
        }

        // Handle createdAt date
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = Self.parseDate(dateString) ?? Date()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }

        // Handle updatedAt date
        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = Self.parseDate(dateString) ?? Date()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        // Try ISO8601 with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // Try ISO8601 without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // Try date only format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.date(from: string)
    }

    var isRecurring: Bool {
        recurrenceRule != nil
    }

    var dueDateTimeDisplay: String? {
        guard let date = dueDate else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var result = dateFormatter.string(from: date)

        if let time = dueTime {
            result += " at \(time)"
        }

        return result
    }

    var reminderDisplay: String? {
        guard let minutes = reminderMinutesBefore else { return nil }

        switch minutes {
        case 0: return "At time of event"
        case 15: return "15 minutes before"
        case 30: return "30 minutes before"
        case 60: return "1 hour before"
        case 120: return "2 hours before"
        case 1440: return "1 day before"
        default:
            if minutes < 60 {
                return "\(minutes) minutes before"
            } else if minutes < 1440 {
                return "\(minutes / 60) hours before"
            } else {
                return "\(minutes / 1440) days before"
            }
        }
    }
}
