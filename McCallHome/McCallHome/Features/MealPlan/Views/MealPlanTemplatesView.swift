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
                                ingredients: viewModel.ingredients,
                                weekStart: weekStart,
                                onApply: {
                                    Task {
                                        await viewModel.applyTemplate(template, to: weekStart!, clearExisting: true)
                                        dismiss()
                                        onApply?()
                                    }
                                },
                                onSave: { updatedTemplate in
                                    Task {
                                        await viewModel.updateTemplate(updatedTemplate)
                                    }
                                },
                                onCopy: {
                                    Task {
                                        await viewModel.copyTemplate(template)
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
                        Text("Swipe right to apply/edit, swipe left to copy/delete")
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
    let ingredients: [IngredientPreference]
    let weekStart: Date?
    let onApply: () -> Void
    let onSave: (MealPlanTemplate) -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var showDetail = false
    @State private var currentTemplate: MealPlanTemplate

    init(
        template: MealPlanTemplate,
        recipes: [Recipe],
        restaurants: [Restaurant],
        ingredients: [IngredientPreference],
        weekStart: Date?,
        onApply: @escaping () -> Void,
        onSave: @escaping (MealPlanTemplate) -> Void,
        onCopy: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.template = template
        self.recipes = recipes
        self.restaurants = restaurants
        self.ingredients = ingredients
        self.weekStart = weekStart
        self.onApply = onApply
        self.onSave = onSave
        self.onCopy = onCopy
        self.onDelete = onDelete
        self._currentTemplate = State(initialValue: template)
    }

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

            Button {
                showDetail = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.purple)
        }
        .sheet(isPresented: $showDetail) {
            TemplateDetailView(
                template: currentTemplate,
                recipes: recipes,
                restaurants: restaurants,
                ingredients: ingredients,
                weekStart: weekStart,
                onApply: onApply,
                onSave: { updatedTemplate in
                    currentTemplate = updatedTemplate
                    onSave(updatedTemplate)
                }
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
    let ingredients: [IngredientPreference]
    let weekStart: Date?
    let onApply: () -> Void
    let onSave: ((MealPlanTemplate) -> Void)?  // Called when template is edited and saved

    @State private var showEditSheet = false
    @State private var currentTemplate: MealPlanTemplate

    init(
        template: MealPlanTemplate,
        recipes: [Recipe],
        restaurants: [Restaurant],
        ingredients: [IngredientPreference],
        weekStart: Date?,
        onApply: @escaping () -> Void,
        onSave: ((MealPlanTemplate) -> Void)? = nil
    ) {
        self.template = template
        self.recipes = recipes
        self.restaurants = restaurants
        self.ingredients = ingredients
        self.weekStart = weekStart
        self.onApply = onApply
        self.onSave = onSave
        self._currentTemplate = State(initialValue: template)
    }

    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            List {
                // Template info section
                if let notes = currentTemplate.notes, !notes.isEmpty {
                    Section {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Notes")
                    }
                }

                // Meals by day
                ForEach(0..<7, id: \.self) { dayIndex in
                    let entries = currentTemplate.entries(for: dayIndex)
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
            .navigationTitle(currentTemplate.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Edit button (only show if onSave is provided)
                        if onSave != nil {
                            Button {
                                showEditSheet = true
                            } label: {
                                Text("Edit")
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Apply button (if weekStart provided)
                        if weekStart != nil {
                            Button("Apply") {
                                onApply()
                                dismiss()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditTemplateSheet(
                    template: currentTemplate,
                    recipes: recipes,
                    restaurants: restaurants,
                    ingredients: ingredients,
                    onSave: { updatedTemplate in
                        currentTemplate = updatedTemplate
                        onSave?(updatedTemplate)
                        showEditSheet = false
                    }
                )
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
    @Published var ingredients: [IngredientPreference] = []
    @Published var isLoading = false
    @Published var error: String?

    private let templateService = MealPlanTemplateService.shared
    private let recipeService = RecipeService.shared
    private let restaurantService = RestaurantService.shared
    private let ingredientService = IngredientPreferenceService.shared
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
            async let ingredientsTask = ingredientService.fetchAllPreferences(for: householdId)

            templates = try await templatesTask
            rotations = try await rotationsTask
            recipes = try await recipesTask
            restaurants = try await restaurantsTask
            ingredients = try await ingredientsTask
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

    func copyTemplate(_ template: MealPlanTemplate) async {
        do {
            let newName = "\(template.name) (Copy)"
            let copy = try await templateService.copyTemplate(template, newName: newName)
            templates.append(copy)
            templates.sort { $0.name < $1.name }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateTemplate(_ template: MealPlanTemplate) async {
        do {
            try await templateService.updateTemplate(template)
            if let index = templates.firstIndex(where: { $0.id == template.id }) {
                templates[index] = template
            }
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

// MARK: - Edit Template Sheet

struct EditTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: MealPlanTemplate
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let ingredients: [IngredientPreference]
    let onSave: (MealPlanTemplate) -> Void

    @State private var name: String
    @State private var notes: String
    @State private var entries: [MealPlanTemplate.TemplateEntry]

    init(template: MealPlanTemplate, recipes: [Recipe], restaurants: [Restaurant], ingredients: [IngredientPreference], onSave: @escaping (MealPlanTemplate) -> Void) {
        self.template = template
        self.recipes = recipes
        self.restaurants = restaurants
        self.ingredients = ingredients
        self.onSave = onSave
        self._name = State(initialValue: template.name)
        self._notes = State(initialValue: template.notes ?? "")
        self._entries = State(initialValue: template.entries)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $name)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Details")
                }

                Section {
                    HStack {
                        Text("Meals")
                        Spacer()
                        Text("\(entries.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Recipes")
                        Spacer()
                        Text("\(entries.filter { $0.recipeId != nil }.count)")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        EditTemplateEntriesView(
                            entries: $entries,
                            recipes: recipes,
                            restaurants: restaurants,
                            ingredients: ingredients
                        )
                    } label: {
                        Text("Edit Meals")
                    }
                } header: {
                    Text("Content")
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var updated = template
                        updated.name = name
                        updated.notes = notes.isEmpty ? nil : notes
                        updated.entries = entries
                        onSave(updated)
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Template Entries View

struct EditTemplateEntriesView: View {
    @Binding var entries: [MealPlanTemplate.TemplateEntry]
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let ingredients: [IngredientPreference]

    @State private var selectedDayIndex: Int?
    @State private var selectedMealType: MealPlanEntry.MealType?
    @State private var showMealPicker = false

    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        List {
            ForEach(0..<7, id: \.self) { dayIndex in
                Section(dayNames[dayIndex]) {
                    ForEach(entries.filter { $0.dayOfWeek == dayIndex }) { entry in
                        entryRow(entry, dayIndex: dayIndex)
                    }
                    .onDelete { indexSet in
                        deleteEntries(at: indexSet, for: dayIndex)
                    }

                    addMealButton(for: dayIndex)
                }
            }
        }
        .navigationTitle("Edit Meals")
        .sheet(isPresented: $showMealPicker) {
            if let dayIndex = selectedDayIndex, let mealType = selectedMealType {
                TemplateMealPickerView(
                    dayIndex: dayIndex,
                    dayName: dayNames[dayIndex],
                    mealType: mealType,
                    recipes: recipes,
                    restaurants: restaurants,
                    ingredients: ingredients,
                    onAdd: { entry in
                        entries.append(entry)
                        showMealPicker = false
                    }
                )
            }
        }
    }

    private func entryRow(_ entry: MealPlanTemplate.TemplateEntry, dayIndex: Int) -> some View {
        HStack {
            Image(systemName: entry.mealType.iconName)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(entryLabel(for: entry))

            Spacer()

            Text(entry.mealType.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func addMealButton(for dayIndex: Int) -> some View {
        Menu {
            ForEach(MealPlanEntry.MealType.allCases, id: \.self) { mealType in
                Button {
                    selectedDayIndex = dayIndex
                    selectedMealType = mealType
                    showMealPicker = true
                } label: {
                    Label(mealType.displayName, systemImage: mealType.iconName)
                }
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                Text("Add Meal")
            }
            .foregroundStyle(.blue)
        }
    }

    private func deleteEntries(at offsets: IndexSet, for dayIndex: Int) {
        let dayEntries = entries.filter { $0.dayOfWeek == dayIndex }
        let idsToRemove = offsets.map { dayEntries[$0].id }
        entries.removeAll { idsToRemove.contains($0.id) }
    }

    private func entryLabel(for entry: MealPlanTemplate.TemplateEntry) -> String {
        if entry.isEatOut {
            if let restaurant = restaurants.first(where: { $0.id == entry.restaurantId }) {
                return restaurant.name
            }
            return entry.eatOutLocation ?? "Eat Out"
        } else if entry.isLeftovers {
            return entry.leftoversNote ?? "Leftovers"
        } else if entry.isIngredientOnly {
            return entry.ingredientName ?? "Ingredient"
        } else if let recipe = recipes.first(where: { $0.id == entry.recipeId }) {
            return recipe.title
        }
        return "Unknown"
    }
}

#Preview {
    MealPlanTemplatesView()
}
