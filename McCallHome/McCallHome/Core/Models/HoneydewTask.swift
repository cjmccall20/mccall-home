//
//  HoneydewTask.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import SwiftUI

struct HoneydewTask: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var dueTime: String?
    var priority: Priority
    var assignedTo: UUID?
    let createdBy: UUID
    var isComplete: Bool
    var completedAt: Date?
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
