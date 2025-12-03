//
//  MealPlanTemplatesView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI
import Combine

struct MealPlanTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MealPlanTemplatesViewModel()

    let weekStart: Date?  // If provided, show "Apply to This Week" option
    let onApply: (() -> Void)?  // Called after applying a template

    init(weekStart: Date? = nil, onApply: (() -> Void)? = nil) {
        self.weekStart = weekStart
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if viewModel.templates.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Saved Weeks",
                            systemImage: "calendar.badge.plus",
                            description: Text("Save a week from your meal plan to reuse it later")
                        )
                    }
                } else {
                    Section {
                        ForEach(viewModel.templates) { template in
                            TemplateRow(
                                template: template,
                                recipes: viewModel.recipes,
                                restaurants: viewModel.restaurants,
                                weekStart: weekStart,
                                onApply: {
                                    Task {
                                        await viewModel.applyTemplate(template, to: weekStart!, clearExisting: true)
                                        dismiss()
                                        onApply?()
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteTemplate(template)
                                    }
                                }
                            )
                        }
                    } header: {
                        Text("Saved Weeks")
                    } footer: {
                        Text("Tap a week to view details or swipe to apply/delete")
                    }
                }

                // Rotations section
                if !viewModel.rotations.isEmpty {
                    Section {
                        ForEach(viewModel.rotations) { rotation in
                            RotationRow(
                                rotation: rotation,
                                templates: viewModel.templates,
                                onToggle: {
                                    Task {
                                        await viewModel.toggleRotation(rotation)
                                    }
                                }
                            )
                        }
                    } header: {
                        Text("Rotation Schedules")
                    } footer: {
                        Text("Rotating schedules automatically cycle through multiple saved weeks")
                    }
                }
            }
            .navigationTitle("Saved Weeks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadData()
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
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: MealPlanTemplate
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let weekStart: Date?
    let onApply: () -> Void
    let onDelete: () -> Void

    @State private var showDetail = false

    var mealCount: Int {
        template.entries.count
    }

    var recipeCount: Int {
        template.entries.filter { $0.recipeId != nil }.count
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    if template.isRotating {
                        Label("Rotating", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(mealCount) meals", systemImage: "fork.knife")
                    Label("\(recipeCount) recipes", systemImage: "book")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let notes = template.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            if weekStart != nil {
                Button {
                    onApply()
                } label: {
                    Label("Apply", systemImage: "calendar.badge.plus")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            TemplateDetailView(
                template: template,
                recipes: recipes,
                restaurants: restaurants,
                weekStart: weekStart,
                onApply: onApply
            )
        }
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let template: MealPlanTemplate
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let weekStart: Date?
    let onApply: () -> Void

    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let entries = template.entries(for: dayIndex)
                    if !entries.isEmpty {
                        Section(dayNames[dayIndex]) {
                            ForEach(MealPlanEntry.MealType.allCases, id: \.self) { mealType in
                                let mealEntries = entries.filter { $0.mealType == mealType }
                                ForEach(mealEntries) { entry in
                                    templateEntryRow(entry)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if weekStart != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Apply") {
                            onApply()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func templateEntryRow(_ entry: MealPlanTemplate.TemplateEntry) -> some View {
        HStack {
            Image(systemName: entry.mealType.iconName)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if entry.isEatOut {
                Image(systemName: "fork.knife")
                    .foregroundStyle(.orange)
                if let restaurant = restaurants.first(where: { $0.id == entry.restaurantId }) {
                    Text(restaurant.name)
                } else {
                    Text(entry.eatOutLocation ?? "Eat Out")
                }
            } else if entry.isLeftovers {
                Image(systemName: "takeoutbag.and.cup.and.straw")
                    .foregroundStyle(.green)
                Text(entry.leftoversNote ?? "Leftovers")
            } else if entry.isIngredientOnly {
                Image(systemName: "carrot")
                    .foregroundStyle(.purple)
                Text(entry.ingredientName ?? "Ingredient")
            } else if let recipe = recipes.first(where: { $0.id == entry.recipeId }) {
                Image(systemName: recipe.dishCategory.iconName)
                    .foregroundStyle(.blue)
                Text(recipe.title)
            }

            Spacer()

            Text(entry.mealType.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Rotation Row

struct RotationRow: View {
    let rotation: MealPlanRotation
    let templates: [MealPlanTemplate]
    let onToggle: () -> Void

    var templateNames: String {
        let names = rotation.templateIds.compactMap { id in
            templates.first(where: { $0.id == id })?.name
        }
        return names.joined(separator: " → ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rotation.name)
                    .font(.headline)

                Text(templateNames)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if rotation.isActive {
                    let currentIndex = rotation.currentIndex + 1
                    let total = rotation.templateIds.count
                    Text("Week \(currentIndex) of \(total)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Toggle("", isOn: .constant(rotation.isActive))
                .labelsHidden()
                .onChange(of: rotation.isActive) { _, _ in
                    onToggle()
                }
        }
    }
}

// MARK: - ViewModel

@MainActor
class MealPlanTemplatesViewModel: ObservableObject {
    @Published var templates: [MealPlanTemplate] = []
    @Published var rotations: [MealPlanRotation] = []
    @Published var recipes: [Recipe] = []
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: String?

    private let templateService = MealPlanTemplateService.shared
    private let recipeService = RecipeService.shared
    private let restaurantService = RestaurantService.shared
    private let authService = AuthService.shared

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    func loadData() async {
        guard let householdId = householdId else { return }

        isLoading = true
        error = nil

        do {
            async let templatesTask = templateService.fetchTemplates(for: householdId)
            async let rotationsTask = templateService.fetchRotations(for: householdId)
            async let recipesTask = recipeService.fetchRecipes(for: householdId)
            async let restaurantsTask = restaurantService.fetchRestaurants(for: householdId)

            templates = try await templatesTask
            rotations = try await rotationsTask
            recipes = try await recipesTask
            restaurants = try await restaurantsTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func applyTemplate(_ template: MealPlanTemplate, to weekStart: Date, clearExisting: Bool) async {
        guard let householdId = householdId else { return }

        do {
            try await templateService.applyTemplate(
                template,
                to: weekStart,
                householdId: householdId,
                clearExisting: clearExisting
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteTemplate(_ template: MealPlanTemplate) async {
        do {
            try await templateService.deleteTemplate(template)
            templates.removeAll { $0.id == template.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleRotation(_ rotation: MealPlanRotation) async {
        var updated = rotation
        updated.isActive.toggle()

        do {
            try await templateService.updateRotation(updated)
            if let index = rotations.firstIndex(where: { $0.id == rotation.id }) {
                rotations[index] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Save Template Sheet

struct SaveTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mealPlanViewModel: MealPlanViewModel

    @State private var name = ""
    @State private var notes = ""
    @State private var addToRotation = false
    @State private var isSaving = false
    @State private var error: String?

    private let templateService = MealPlanTemplateService.shared

    var canSave: Bool {
        !name.isEmpty && !mealPlanViewModel.entries.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Week Name", text: $name)
                        .textContentType(.name)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Template Details")
                } footer: {
                    Text("Give this week a memorable name like \"Busy Week\" or \"Meal Prep Week\"")
                }

                Section {
                    HStack {
                        Text("Meals")
                        Spacer()
                        Text("\(mealPlanViewModel.entries.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Recipes")
                        Spacer()
                        Text("\(mealPlanViewModel.entries.filter { $0.recipeId != nil }.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Week")
                        Spacer()
                        Text(mealPlanViewModel.weekRangeText)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Week Summary")
                }

                Section {
                    Toggle("Add to Rotation", isOn: $addToRotation)
                } footer: {
                    Text("Rotation schedules automatically cycle through saved weeks")
                }
            }
            .navigationTitle("Save Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(!canSave || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isSaving)
    }

    private func saveTemplate() {
        guard let householdId = mealPlanViewModel.householdId else { return }
        isSaving = true

        Task {
            do {
                var template = try await templateService.saveCurrentWeekAsTemplate(
                    name: name,
                    weekStart: mealPlanViewModel.currentWeekStart,
                    householdId: householdId
                )

                if !notes.isEmpty {
                    template.notes = notes
                    try await templateService.updateTemplate(template)
                }

                dismiss()
            } catch {
                self.error = error.localizedDescription
                isSaving = false
            }
        }
    }
}

#Preview {
    MealPlanTemplatesView()
}
