//
//  HoneydewRowView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct HoneydewRowView: View {
    let task: HoneydewTask
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
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isComplete)
                    .foregroundStyle(task.isComplete ? .secondary : .primary)

                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dueDate.formatted(as: .medium))
                            .font(.caption)
                    }
                    .foregroundStyle(dueDateColor(dueDate))
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
        if date < Date() && !task.isComplete {
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
                dueTime: nil,
                priority: .medium,
                assignedTo: nil,
                createdBy: UUID(),
                isComplete: false,
                completedAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            onToggle: {}
        )
    }
}
