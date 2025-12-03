//
//  HouseStaplesView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import Combine

struct HouseStaplesView: View {
    @StateObject private var viewModel = HouseStaplesViewModel()
    @State private var showAddSheet = false
    @State private var editingStaple: HouseStaple?

    var body: some View {
        List {
            // Info Section
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Items here will automatically be added to every grocery list you generate.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Staples by Category
            ForEach(viewModel.groupedStaples.keys.sorted(), id: \.self) { category in
                Section(category) {
                    ForEach(viewModel.groupedStaples[category] ?? []) { staple in
                        HouseStapleRow(staple: staple) {
                            editingStaple = staple
                        } onToggle: {
                            Task {
                                await viewModel.toggleStaple(staple)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let staples = viewModel.groupedStaples[category] ?? []
                        for index in indexSet {
                            Task {
                                await viewModel.deleteStaple(staples[index])
                            }
                        }
                    }
                }
            }

            // Empty State
            if viewModel.staples.isEmpty && !viewModel.isLoading {
                Section {
                    ContentUnavailableView(
                        "No House Staples",
                        systemImage: "basket",
                        description: Text("Add items that should appear on every grocery list")
                    )
                }
            }
        }
        .navigationTitle("House Staples")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadStaples()
        }
        .refreshable {
            await viewModel.loadStaples()
        }
        .sheet(isPresented: $showAddSheet) {
            AddEditStapleView(viewModel: viewModel, staple: nil)
        }
        .sheet(item: $editingStaple) { staple in
            AddEditStapleView(viewModel: viewModel, staple: staple)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

// MARK: - Staple Row

struct HouseStapleRow: View {
    let staple: HouseStaple
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button {
                onToggle()
            } label: {
                Image(systemName: staple.isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(staple.isActive ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(staple.name)
                    .strikethrough(!staple.isActive)
                    .foregroundStyle(staple.isActive ? .primary : .secondary)

                if let quantity = staple.quantity, !quantity.isEmpty {
                    Text(quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Add/Edit Staple View

struct AddEditStapleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HouseStaplesViewModel
    let staple: HouseStaple?

    @State private var name = ""
    @State private var quantity = ""
    @State private var category = "Other"
    @State private var notes = ""
    @State private var isSaving = false

    var isEditing: Bool { staple != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $name)

                    TextField("Quantity (optional)", text: $quantity)
                        .keyboardType(.default)

                    Picker("Category", selection: $category) {
                        ForEach(HouseStaple.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text(isEditing ? "Save Changes" : "Add Staple")
                            }
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .navigationTitle(isEditing ? "Edit Staple" : "Add Staple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let staple = staple {
                    name = staple.name
                    quantity = staple.quantity ?? ""
                    category = staple.category
                    notes = staple.notes ?? ""
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        isSaving = true
        Task {
            if let existing = staple {
                var updated = existing
                updated.name = name
                updated.quantity = quantity.isEmpty ? nil : quantity
                updated.category = category
                updated.notes = notes.isEmpty ? nil : notes
                await viewModel.updateStaple(updated)
            } else {
                await viewModel.addStaple(
                    name: name,
                    quantity: quantity.isEmpty ? nil : quantity,
                    category: category,
                    notes: notes.isEmpty ? nil : notes
                )
            }
            isSaving = false
            if viewModel.error == nil {
                dismiss()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class HouseStaplesViewModel: ObservableObject {
    @Published var staples: [HouseStaple] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = HouseStapleService.shared
    private let authService = AuthService.shared

    var groupedStaples: [String: [HouseStaple]] {
        Dictionary(grouping: staples, by: { $0.category })
    }

    func loadStaples() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        isLoading = staples.isEmpty
        do {
            staples = try await service.fetchStaples(for: householdId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func addStaple(name: String, quantity: String?, category: String, notes: String?) async {
        guard let householdId = authService.currentUser?.householdId else { return }

        let staple = HouseStaple(
            householdId: householdId,
            name: name,
            quantity: quantity,
            category: category,
            notes: notes
        )

        do {
            let created = try await service.createStaple(staple)
            staples.append(created)
            staples.sort { $0.name < $1.name }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateStaple(_ staple: HouseStaple) async {
        do {
            try await service.updateStaple(staple)
            if let index = staples.firstIndex(where: { $0.id == staple.id }) {
                staples[index] = staple
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleStaple(_ staple: HouseStaple) async {
        do {
            try await service.toggleActive(staple)
            if let index = staples.firstIndex(where: { $0.id == staple.id }) {
                staples[index].isActive.toggle()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteStaple(_ staple: HouseStaple) async {
        do {
            try await service.deleteStaple(staple.id)
            staples.removeAll { $0.id == staple.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        HouseStaplesView()
    }
}
