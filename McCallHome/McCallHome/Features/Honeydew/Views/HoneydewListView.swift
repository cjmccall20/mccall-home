//
//  HoneydewListView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct HoneydewListView: View {
    @StateObject private var viewModel = HoneydewViewModel()
    @State private var showCreateTask = false

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if viewModel.isLoading && viewModel.tasks.isEmpty {
                        ProgressView("Loading tasks...")
                    } else if viewModel.filteredTasks.isEmpty {
                        ContentUnavailableView(
                            "No Tasks",
                            systemImage: "checklist",
                            description: Text("Tap + to add a new task")
                        )
                    } else {
                        taskList
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateTask = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Honeydew")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(HoneydewViewModel.TaskFilter.allCases, id: \.self) { filter in
                            Button {
                                viewModel.filter = filter
                            } label: {
                                if viewModel.filter == filter {
                                    Label(filter.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(filter.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.fetchTasks()
            }
            .task {
                await viewModel.fetchTasks()
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    private var taskList: some View {
        List {
            if viewModel.filter == .complete {
                // Grouped by day view for completed tasks
                ForEach(viewModel.completedTasksByDay, id: \.date) { group in
                    Section {
                        ForEach(group.tasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task, viewModel: viewModel)
                            } label: {
                                HoneydewRowView(
                                    task: task,
                                    assigneeName: viewModel.memberName(for: task.assignedTo)
                                ) {
                                    Task {
                                        await viewModel.toggleComplete(task)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let task = group.tasks[index]
                                Task {
                                    await viewModel.deleteTask(task)
                                }
                            }
                        }
                    } header: {
                        Text(formatGroupDate(group.date))
                    }
                }
            } else {
                ForEach(viewModel.filteredTasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task, viewModel: viewModel)
                    } label: {
                        HoneydewRowView(
                            task: task,
                            assigneeName: viewModel.memberName(for: task.assignedTo)
                        ) {
                            Task {
                                await viewModel.toggleComplete(task)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let task = viewModel.filteredTasks[index]
                        Task {
                            await viewModel.deleteTask(task)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private func formatGroupDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview {
    HoneydewListView()
}
