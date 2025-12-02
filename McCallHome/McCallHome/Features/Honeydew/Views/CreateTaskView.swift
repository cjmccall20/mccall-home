//
//  CreateTaskView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HoneydewViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasDueTime = false
    @State private var dueTime = Date()
    @State private var priority: HoneydewTask.Priority = .medium
    @State private var selectedMemberId: UUID? = nil  // nil = Anyone

    // Recurrence
    @State private var isRecurring = false
    @State private var recurrenceType: HoneydewTask.RecurrenceRule.RecurrenceType = .weekly
    @State private var selectedDayOfWeek = 0 // 0 = Sunday
    @State private var selectedDayOfMonth = 1

    // Reminder
    @State private var hasReminder = false
    @State private var reminderMinutes = 30

    let reminderOptions = [
        (15, "15 minutes before"),
        (30, "30 minutes before"),
        (60, "1 hour before"),
        (120, "2 hours before"),
        (1440, "1 day before")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Due Date & Time") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)

                        Toggle("Set due time", isOn: $hasDueTime)
                        if hasDueTime {
                            DatePicker("Due time", selection: $dueTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }

                if hasDueDate {
                    Section("Recurrence") {
                        Toggle("Repeat this task", isOn: $isRecurring)

                        if isRecurring {
                            Picker("Repeat", selection: $recurrenceType) {
                                Text("Daily").tag(HoneydewTask.RecurrenceRule.RecurrenceType.daily)
                                Text("Weekly").tag(HoneydewTask.RecurrenceRule.RecurrenceType.weekly)
                                Text("Monthly").tag(HoneydewTask.RecurrenceRule.RecurrenceType.monthly)
                            }

                            if recurrenceType == .weekly {
                                Picker("Day of week", selection: $selectedDayOfWeek) {
                                    Text("Sunday").tag(0)
                                    Text("Monday").tag(1)
                                    Text("Tuesday").tag(2)
                                    Text("Wednesday").tag(3)
                                    Text("Thursday").tag(4)
                                    Text("Friday").tag(5)
                                    Text("Saturday").tag(6)
                                }
                            }

                            if recurrenceType == .monthly {
                                Picker("Day of month", selection: $selectedDayOfMonth) {
                                    ForEach(1...28, id: \.self) { day in
                                        Text("\(day)").tag(day)
                                    }
                                }
                            }
                        }
                    }

                    if hasDueTime {
                        Section("Reminder") {
                            Toggle("Set reminder", isOn: $hasReminder)

                            if hasReminder {
                                Picker("Remind me", selection: $reminderMinutes) {
                                    ForEach(reminderOptions, id: \.0) { option in
                                        Text(option.1).tag(option.0)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Assignment") {
                    Picker("Assigned To", selection: $selectedMemberId) {
                        Text("Anyone").tag(nil as UUID?)
                        ForEach(viewModel.householdMembers) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }
                }

                Section("Priority") {
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
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createTask() {
        let recurrenceRule: HoneydewTask.RecurrenceRule? = {
            guard isRecurring && hasDueDate else { return nil }

            var rule = HoneydewTask.RecurrenceRule(type: recurrenceType)

            switch recurrenceType {
            case .weekly:
                rule.dayOfWeek = selectedDayOfWeek
            case .monthly:
                rule.dayOfMonth = selectedDayOfMonth
            case .daily:
                break
            }

            return rule
        }()

        let dueTimeString: String? = {
            guard hasDueTime && hasDueDate else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: dueTime)
        }()

        Task {
            await viewModel.createTask(
                title: title,
                description: description.isEmpty ? nil : description,
                dueDate: hasDueDate ? dueDate : nil,
                dueTime: dueTimeString,
                priority: priority,
                assignedTo: selectedMemberId,
                recurrenceRule: recurrenceRule,
                reminderMinutesBefore: hasReminder && hasDueTime ? reminderMinutes : nil
            )
            dismiss()
        }
    }
}

#Preview {
    CreateTaskView(viewModel: HoneydewViewModel())
}
