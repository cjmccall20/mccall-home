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
    @Published var isLoading = false
    @Published var error: String?
    @Published var filter: TaskFilter = .all

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case mine = "Mine"
        case incomplete = "To Do"
        case complete = "Done"
    }

    private let taskService = TaskService.shared
    private let authService = AuthService.shared

    var filteredTasks: [HoneydewTask] {
        switch filter {
        case .all:
            return tasks
        case .mine:
            guard let userId = authService.currentUser?.id else { return tasks }
            return tasks.filter { $0.assignedTo == userId }
        case .incomplete:
            return tasks.filter { !$0.isComplete }
        case .complete:
            return tasks.filter { $0.isComplete }
        }
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    func fetchTasks() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            tasks = try await taskService.fetchTasks(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func createTask(title: String, description: String?, dueDate: Date?, priority: HoneydewTask.Priority, assignedTo: UUID?) async {
        guard let householdId = householdId,
              let userId = authService.currentUser?.id else { return }

        let task = HoneydewTask(
            id: UUID(),
            householdId: householdId,
            title: title,
            description: description,
            dueDate: dueDate,
            dueTime: nil,
            priority: priority,
            assignedTo: assignedTo,
            createdBy: userId,
            isComplete: false,
            completedAt: nil,
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
            try await taskService.toggleComplete(task)
            await fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
