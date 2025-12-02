//
//  TaskService.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import Foundation
import Supabase

@MainActor
class TaskService {
    static let shared = TaskService()
    private init() {}

    func fetchTasks(for householdId: UUID) async throws -> [HoneydewTask] {
        let response: [HoneydewTask] = try await supabase
            .from("honeydew_tasks")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("due_date", ascending: true)
            .execute()
            .value
        return response
    }

    func createTask(_ task: HoneydewTask) async throws {
        try await supabase
            .from("honeydew_tasks")
            .insert(task)
            .execute()
    }

    func updateTask(_ task: HoneydewTask) async throws {
        try await supabase
            .from("honeydew_tasks")
            .update(task)
            .eq("id", value: task.id.uuidString)
            .execute()
    }

    func deleteTask(_ task: HoneydewTask) async throws {
        try await supabase
            .from("honeydew_tasks")
            .delete()
            .eq("id", value: task.id.uuidString)
            .execute()
    }

    func toggleComplete(_ task: HoneydewTask) async throws {
        var updatedTask = task
        updatedTask.isComplete.toggle()
        updatedTask.completedAt = updatedTask.isComplete ? Date() : nil
        updatedTask.updatedAt = Date()
        try await updateTask(updatedTask)
    }
}
