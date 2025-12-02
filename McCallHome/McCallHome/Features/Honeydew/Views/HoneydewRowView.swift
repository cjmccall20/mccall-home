//
//  HoneydewRowView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct HoneydewRowView: View {
    let task: HoneydewTask
    let assigneeName: String?
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isComplete ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isComplete)
                        .foregroundStyle(task.isComplete ? .secondary : .primary)

                    // Recurring indicator
                    if task.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                // Due date, time, and assignment
                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(dueDate.formatted(as: .medium))
                                .font(.caption)
                        }
                        .foregroundStyle(dueDateColor(dueDate))
                    }

                    if let dueTime = task.dueTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(dueTime)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if task.reminderMinutesBefore != nil {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    // Assignee indicator
                    if let name = assigneeName {
                        HStack(spacing: 4) {
                            Image(systemName: "person")
                                .font(.caption)
                            Text(name)
                                .font(.caption)
                        }
                        .foregroundStyle(.purple)
                    }
                }
            }

            Spacer()

            // Priority indicator
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private func dueDateColor(_ date: Date) -> Color {
        if date < Calendar.current.startOfDay(for: Date()) && !task.isComplete {
            return .red
        } else if date.isToday {
            return .orange
        } else if date.isTomorrow {
            return .blue
        }
        return .secondary
    }
}

#Preview {
    List {
        HoneydewRowView(
            task: HoneydewTask(
                id: UUID(),
                householdId: UUID(),
                title: "Buy groceries",
                description: nil,
                dueDate: Date(),
                dueTime: "14:30",
                priority: .medium,
                assignedTo: nil,
                createdBy: UUID(),
                isComplete: false,
                completedAt: nil,
                recurrenceRule: HoneydewTask.RecurrenceRule(type: .weekly, dayOfWeek: 1),
                reminderMinutesBefore: 30,
                nextOccurrence: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            assigneeName: "Cooper",
            onToggle: {}
        )

        HoneydewRowView(
            task: HoneydewTask(
                id: UUID(),
                householdId: UUID(),
                title: "Clean kitchen",
                description: nil,
                dueDate: Date().adding(days: -1),
                dueTime: nil,
                priority: .high,
                assignedTo: nil,
                createdBy: UUID(),
                isComplete: false,
                completedAt: nil,
                recurrenceRule: nil,
                reminderMinutesBefore: nil,
                nextOccurrence: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            assigneeName: nil,
            onToggle: {}
        )
    }
}
