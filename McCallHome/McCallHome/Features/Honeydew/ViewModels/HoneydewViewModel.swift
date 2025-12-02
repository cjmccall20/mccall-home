//
//  HoneydewViewModel.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Combine

@MainActor
class HoneydewViewModel: ObservableObject {
    @Published var tasks: [HoneydewTask] = []
    @Published var householdMembers: [HouseholdMember] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var filter: TaskFilter = .incomplete  // Default to To Do

    enum TaskFilter: String, CaseIterable {
        case incomplete = "To Do"
        case complete = "Done"
        case all = "All"
        case recurring = "Recurring"
    }

    private let taskService = TaskService.shared
    private let authService = AuthService.shared
    private let memberService = HouseholdMemberService.shared

    var filteredTasks: [HoneydewTask] {
        let filtered: [HoneydewTask]
        switch filter {
        case .all:
            filtered = tasks
        case .incomplete:
            filtered = tasks.filter { !$0.isComplete }
        case .complete:
            filtered = tasks.filter { $0.isComplete }
        case .recurring:
            filtered = tasks.filter { $0.isRecurring }
        }

        // Sort by: incomplete first, then by due date (soonest first), then by priority
        return filtered.sorted { task1, task2 in
            // Incomplete tasks first
            if task1.isComplete != task2.isComplete {
                return !task1.isComplete
            }
            // Then by due date (tasks with due dates first, soonest first)
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            } else if task1.dueDate != nil {
                return true
            } else if task2.dueDate != nil {
                return false
            }
            // Finally by priority (higher priority first)
            return priorityOrder(task1.priority) > priorityOrder(task2.priority)
        }
    }

    // Completed tasks grouped by day (most recent first)
    var completedTasksByDay: [(date: Date, tasks: [HoneydewTask])] {
        let completedTasks = tasks.filter { $0.isComplete }

        // Group by completion date
        let grouped = Dictionary(grouping: completedTasks) { task -> Date in
            guard let completedAt = task.completedAt else {
                return Calendar.current.startOfDay(for: task.updatedAt)
            }
            return Calendar.current.startOfDay(for: completedAt)
        }

        // Sort by date descending (most recent first)
        return grouped.map { (date: $0.key, tasks: $0.value) }
            .sorted { $0.date > $1.date }
    }

    // Helper to get member name for a task
    func memberName(for memberId: UUID?) -> String? {
        guard let memberId = memberId else { return nil }
        return householdMembers.first { $0.id == memberId }?.name
    }

    private func priorityOrder(_ priority: HoneydewTask.Priority) -> Int {
        switch priority {
        case .urgent: return 3
        case .high: return 2
        case .medium: return 1
        case .low: return 0
        }
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    // Tasks grouped by status
    var overdueTasks: [HoneydewTask] {
        tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isComplete else { return false }
            return dueDate < Calendar.current.startOfDay(for: Date())
        }
    }

    var todayTasks: [HoneydewTask] {
        tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isComplete else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    var upcomingTasks: [HoneydewTask] {
        tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isComplete else { return false }
            let today = Calendar.current.startOfDay(for: Date())
            return dueDate > today && !Calendar.current.isDateInToday(dueDate)
        }
    }

    func fetchTasks() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            // Fetch tasks and household members in parallel
            async let tasksResult = taskService.fetchTasks(for: householdId)
            async let membersResult = memberService.fetchMembers(for: householdId)

            tasks = try await tasksResult
            householdMembers = try await membersResult
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func createTask(
        title: String,
        description: String?,
        dueDate: Date?,
        dueTime: String?,
        priority: HoneydewTask.Priority,
        assignedTo: UUID?,
        recurrenceRule: HoneydewTask.RecurrenceRule?,
        reminderMinutesBefore: Int?
    ) async {
        guard let householdId = householdId else { return }

        // In dev mode, createdBy must be nil since dev user isn't in profiles table
        // (profiles requires FK to auth.users which we bypass in dev mode)
        let createdBy: UUID? = Config.skipAuthForDevelopment ? nil : authService.currentUser?.id

        let task = HoneydewTask(
            id: UUID(),
            householdId: householdId,
            title: title,
            description: description,
            dueDate: dueDate,
            dueTime: dueTime,
            priority: priority,
            assignedTo: assignedTo,  // Now references household_member_id
            createdBy: createdBy,
            isComplete: false,
            completedAt: nil,
            recurrenceRule: recurrenceRule,
            reminderMinutesBefore: reminderMinutesBefore,
            nextOccurrence: calculateNextOccurrence(from: dueDate, rule: recurrenceRule),
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await taskService.createTask(task)
            await fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // Legacy method for backward compatibility
    func createTask(title: String, description: String?, dueDate: Date?, priority: HoneydewTask.Priority, assignedTo: UUID?) async {
        await createTask(
            title: title,
            description: description,
            dueDate: dueDate,
            dueTime: nil,
            priority: priority,
            assignedTo: assignedTo,
            recurrenceRule: nil,
            reminderMinutesBefore: nil
        )
    }

    func updateTask(_ task: HoneydewTask) async {
        do {
            try await taskService.updateTask(task)
            await fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteTask(_ task: HoneydewTask) async {
        do {
            try await taskService.deleteTask(task)
            await fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleComplete(_ task: HoneydewTask) async {
        do {
            // If completing a recurring task, create next occurrence
            if !task.isComplete && task.isRecurring {
                try await taskService.toggleComplete(task)
                await createNextOccurrence(for: task)
            } else {
                try await taskService.toggleComplete(task)
            }
            await fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Recurring Tasks

    private func calculateNextOccurrence(from date: Date?, rule: HoneydewTask.RecurrenceRule?) -> Date? {
        guard let date = date, let rule = rule else { return nil }

        let calendar = Calendar.current

        switch rule.type {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            if let dayOfWeek = rule.dayOfWeek {
                // Find next occurrence of that day of week
                var nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
                while calendar.component(.weekday, from: nextDate) != (dayOfWeek + 1) { // weekday is 1-indexed
                    nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
                }
                return nextDate
            }
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            if let dayOfMonth = rule.dayOfMonth {
                // Find next occurrence of that day in a future month
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = dayOfMonth
                if let nextDate = calendar.date(from: components), nextDate > date {
                    return nextDate
                }
                // Move to next month
                components.month! += 1
                return calendar.date(from: components)
            }
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }

    private func createNextOccurrence(for task: HoneydewTask) async {
        guard let rule = task.recurrenceRule,
              let dueDate = task.dueDate,
              let householdId = householdId else { return }

        // In dev mode, createdBy must be nil since dev user isn't in profiles table
        let createdBy: UUID? = Config.skipAuthForDevelopment ? nil : authService.currentUser?.id

        let nextDueDate = calculateNextOccurrence(from: dueDate, rule: rule)

        let newTask = HoneydewTask(
            id: UUID(),
            householdId: householdId,
            title: task.title,
            description: task.description,
            dueDate: nextDueDate,
            dueTime: task.dueTime,
            priority: task.priority,
            assignedTo: task.assignedTo,  // Preserve assignment for recurring tasks
            createdBy: createdBy,
            isComplete: false,
            completedAt: nil,
            recurrenceRule: rule,
            reminderMinutesBefore: task.reminderMinutesBefore,
            nextOccurrence: calculateNextOccurrence(from: nextDueDate, rule: rule),
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await taskService.createTask(newTask)
        } catch {
            print("Failed to create next occurrence: \(error)")
        }
    }
}
