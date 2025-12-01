//
//  TaskDetailView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HoneydewViewModel

    let task: HoneydewTask

    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var priority: HoneydewTask.Priority
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    init(task: HoneydewTask, viewModel: HoneydewViewModel) {
        self.task = task
        self.viewModel = viewModel
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _priority = State(initialValue: task.priority)
    }

    var body: some View {
        Form {
            Section("Task") {
                if isEditing {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    Text(task.title)
                        .font(.headline)
                    if let desc = task.description, !desc.isEmpty {
                        Text(desc)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Due Date") {
                if isEditing {
                    Toggle("Has due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }
                } else if let date = task.dueDate {
                    LabeledContent("Due", value: date.formatted(as: .medium))
                } else {
                    Text("No due date")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Priority") {
                if isEditing {
                    Picker("Priority", selection: $priority) {
                        ForEach(HoneydewTask.Priority.allCases, id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(p.color)
                                    .frame(width: 8, height: 8)
                                Text(p.rawValue.capitalized)
                            }
                            .tag(p)
                        }
                    }
                } else {
                    HStack {
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 10, height: 10)
                        Text(task.priority.rawValue.capitalized)
                    }
                }
            }

            Section("Status") {
                HStack {
                    Text(task.isComplete ? "Completed" : "Pending")
                    Spacer()
                    if task.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Button(task.isComplete ? "Mark Incomplete" : "Mark Complete") {
                    Task {
                        await viewModel.toggleComplete(task)
                        dismiss()
                    }
                }
            }

            if isEditing {
                Section {
                    Button("Delete Task", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        isEditing = true
                    }
                }
            }
        }
        .confirmationDialog("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTask(task)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this task?")
        }
    }

    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description.isEmpty ? nil : description
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.priority = priority
        updatedTask.updatedAt = Date()

        Task {
            await viewModel.updateTask(updatedTask)
            isEditing = false
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(
            task: HoneydewTask(
                id: UUID(),
                householdId: UUID(),
                title: "Sample Task",
                description: "This is a sample description",
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
            viewModel: HoneydewViewModel()
        )
    }
}
