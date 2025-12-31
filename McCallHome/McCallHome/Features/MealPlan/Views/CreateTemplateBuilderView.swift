//
//  CreateTemplateBuilderView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

/// View for creating a new meal plan template from scratch - mirrors MealPlanView layout
struct CreateTemplateBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MealPlanTemplatesViewModel

    @State private var name = ""
    @State private var notes = ""
    @State private var entries: [MealPlanTemplate.TemplateEntry] = []
    @State private var selectedDayIndex: Int?
    @State private var selectedMealType: MealPlanEntry.MealType?
    @State private var showMealPicker = false
    @State private var showMealDetail = false
    @State private var showNameEditor = false
    @State private var isSaving = false

    private let templateService = MealPlanTemplateService.shared
    private let authService = AuthService.shared

    let dayNames = ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"]

    var canSave: Bool {
        !entries.isEmpty  // Name is optional - we'll generate a default
    }

    /// Generate a default template name based on existing template count
    var defaultTemplateName: String {
        let existingCount = viewModel.templates.count
        return "Template #\(existingCount + 1)"
    }

    var householdId: UUID? {
        authService.currentUser?.householdId
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Template info header (tap to edit name)
                templateInfoHeader

                Divider()

                // Week grid - mirrors MealPlanView layout
                ScrollView {
                    weekGrid
                        .padding()
                }
            }
            .navigationTitle("Create Template")
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
            .sheet(isPresented: $showMealPicker) {
                if let dayIndex = selectedDayIndex, let mealType = selectedMealType {
                    TemplateMealPickerView(
                        dayIndex: dayIndex,
                        dayName: dayNames[dayIndex],
                        mealType: mealType,
                        recipes: viewModel.recipes,
                        restaurants: viewModel.restaurants,
                        ingredients: viewModel.ingredients,
                        onAdd: { entry in
                            entries.append(entry)
                        }
                    )
                }
            }
            .sheet(isPresented: $showMealDetail) {
                if let dayIndex = selectedDayIndex, let mealType = selectedMealType {
                    TemplateMealDetailView(
                        dayIndex: dayIndex,
                        dayName: dayNames[dayIndex],
                        mealType: mealType,
                        entries: $entries,
                        recipes: viewModel.recipes,
                        restaurants: viewModel.restaurants,
                        ingredients: viewModel.ingredients
                    )
                }
            }
            .sheet(isPresented: $showNameEditor) {
                TemplateNameEditorSheet(name: $name, notes: $notes)
            }
        }
    }

    private var templateInfoHeader: some View {
        Button {
            showNameEditor = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if name.isEmpty {
                        Text(defaultTemplateName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Tap to customize name")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    HStack(spacing: 12) {
                        Text("\(entries.count) meals")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.bar)
        }
        .buttonStyle(.plain)
    }

    private var weekGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
            ForEach(0..<7, id: \.self) { dayIndex in
                TemplateDayPlanView(
                    dayIndex: dayIndex,
                    dayName: dayNames[dayIndex],
                    entries: entriesForDay(dayIndex),
                    recipes: viewModel.recipes,
                    restaurants: viewModel.restaurants,
                    onEmptySlotTap: { mealType in
                        selectedDayIndex = dayIndex
                        selectedMealType = mealType
                        showMealPicker = true
                    },
                    onFilledSlotTap: { mealType in
                        selectedDayIndex = dayIndex
                        selectedMealType = mealType
                        showMealDetail = true
                    },
                    onAddDishTap: { mealType in
                        selectedDayIndex = dayIndex
                        selectedMealType = mealType
                        showMealPicker = true
                    },
                    onRemove: { entry in
                        entries.removeAll { $0.id == entry.id }
                    }
                )
            }
        }
    }

    private func entriesForDay(_ dayIndex: Int) -> [MealPlanTemplate.TemplateEntry] {
        entries.filter { $0.dayOfWeek == dayIndex }
    }

    private func saveTemplate() {
        guard let householdId = householdId else { return }
        isSaving = true

        Task {
            do {
                // Use provided name or generate default
                let templateName = name.isEmpty ? defaultTemplateName : name

                let template = MealPlanTemplate(
                    householdId: householdId,
                    name: templateName,
                    entries: entries,
                    notes: notes.isEmpty ? nil : notes
                )
                try await templateService.createTemplate(template)
                await viewModel.loadData()
                dismiss()
            } catch {
                viewModel.error = error.localizedDescription
                isSaving = false
            }
        }
    }
}

// MARK: - Template Name Editor Sheet

struct TemplateNameEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var notes: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $name)
                        .textContentType(.name)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give this template a memorable name like \"Busy Week\" or \"Meal Prep Week\"")
                }

                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Template Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Template Day Plan View (mirrors DayPlanView)

struct TemplateDayPlanView: View {
    let dayIndex: Int
    let dayName: String
    let entries: [MealPlanTemplate.TemplateEntry]
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let onEmptySlotTap: (MealPlanEntry.MealType) -> Void
    let onFilledSlotTap: (MealPlanEntry.MealType) -> Void
    let onAddDishTap: (MealPlanEntry.MealType) -> Void
    let onRemove: (MealPlanTemplate.TemplateEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            HStack {
                Text(dayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // Meal slots
            VStack(spacing: 6) {
                ForEach(MealPlanEntry.MealType.allCases, id: \.self) { mealType in
                    mealSlotView(for: mealType)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func mealSlotView(for mealType: MealPlanEntry.MealType) -> some View {
        let slotEntries = entries.filter { $0.mealType == mealType }

        VStack(spacing: 4) {
            if slotEntries.isEmpty {
                // Empty slot - tap to add
                HStack(spacing: 8) {
                    Image(systemName: mealType.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Button {
                        onEmptySlotTap(mealType)
                    } label: {
                        HStack {
                            Text(mealType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                // Has entries - tap to view detail
                ForEach(slotEntries.enumerated(), id: \.element.id) { index, entry in
                    HStack(spacing: 8) {
                        // Only show meal icon on first entry
                        if index == 0 {
                            Image(systemName: mealType.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                        } else {
                            // Indent subsequent entries
                            Color.clear.frame(width: 16)
                        }

                        Button {
                            onFilledSlotTap(mealType)
                        } label: {
                            HStack {
                                entryContentView(for: entry)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            onRemove(entry)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(mealType.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Add more button when there are already entries
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16)

                    Button {
                        onAddDishTap(mealType)
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.caption2)
                            Text("Add dish")
                                .font(.caption2)
                            Spacer()
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func entryContentView(for entry: MealPlanTemplate.TemplateEntry) -> some View {
        if entry.isEatOut {
            Image(systemName: "fork.knife")
                .font(.caption)
                .foregroundStyle(.orange)
            if let restaurant = restaurants.first(where: { $0.id == entry.restaurantId }) {
                Text(restaurant.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            } else {
                Text(entry.eatOutLocation ?? "Eat Out")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        } else if entry.isLeftovers {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.caption)
                .foregroundStyle(.green)
            Text(entry.leftoversNote ?? "Leftovers")
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else if entry.isIngredientOnly {
            Image(systemName: "carrot")
                .font(.caption)
                .foregroundStyle(.purple)
            Text(entry.ingredientName ?? "Ingredient")
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else if let recipe = recipes.first(where: { $0.id == entry.recipeId }) {
            Image(systemName: recipe.dishCategory.iconName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(recipe.title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Template Meal Detail View

struct TemplateMealDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let dayIndex: Int
    let dayName: String
    let mealType: MealPlanEntry.MealType
    @Binding var entries: [MealPlanTemplate.TemplateEntry]
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let ingredients: [IngredientPreference]

    @State private var showMealPicker = false

    var slotEntries: [MealPlanTemplate.TemplateEntry] {
        entries.filter { $0.dayOfWeek == dayIndex && $0.mealType == mealType }
    }

    var body: some View {
        NavigationStack {
            List {
                // Current dishes
                Section {
                    if slotEntries.isEmpty {
                        Text("No dishes planned")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(slotEntries) { entry in
                            entryRow(entry)
                        }
                        .onDelete { indexSet in
                            let idsToDelete = indexSet.map { slotEntries[$0].id }
                            entries.removeAll { idsToDelete.contains($0.id) }
                        }
                    }
                } header: {
                    Text("Dishes")
                } footer: {
                    if !slotEntries.isEmpty {
                        Text("Swipe left to remove a dish")
                    }
                }

                // Add dish button
                Section {
                    Button {
                        showMealPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add Dish")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("\(mealType.displayName) - \(dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMealPicker) {
                TemplateMealPickerView(
                    dayIndex: dayIndex,
                    dayName: dayName,
                    mealType: mealType,
                    recipes: recipes,
                    restaurants: restaurants,
                    ingredients: ingredients,
                    onAdd: { entry in
                        entries.append(entry)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: MealPlanTemplate.TemplateEntry) -> some View {
        HStack {
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
        }
    }
}

// MARK: - Template Meal Picker View (mirrors MealPickerView)

struct TemplateMealPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let dayIndex: Int
    let dayName: String
    let mealType: MealPlanEntry.MealType
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let ingredients: [IngredientPreference]
    let onAdd: (MealPlanTemplate.TemplateEntry) -> Void

    @State private var searchText = ""
    @State private var showEatOutSheet = false
    @State private var showLeftoversSheet = false
    @State private var showIngredientSheet = false
    @State private var selectedRecipe: Recipe?
    @State private var showServingsSheet = false
    @State private var showAllRecipes = false
    @State private var selectedDishCategory: Recipe.DishCategory?

    @State private var pendingDismiss = false

    // Available dish categories that have recipes
    var availableDishCategories: [Recipe.DishCategory] {
        let categories = Set(recipesForMealType.map { $0.dishCategory })
        return Recipe.DishCategory.allCases.filter { categories.contains($0) }
    }

    // Recipes that match the meal category (breakfast/lunch/dinner)
    var recipesForMealType: [Recipe] {
        if showAllRecipes {
            return recipes
        }
        return recipes.filter { $0.mealCategory.matches(mealType) }
    }

    // Filter by dish category
    var recipesForDishCategory: [Recipe] {
        guard let category = selectedDishCategory else {
            return recipesForMealType
        }
        return recipesForMealType.filter { $0.dishCategory == category }
    }

    // Further filter by search text
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipesForDishCategory
        }
        return recipesForDishCategory.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var hasOtherRecipes: Bool {
        !showAllRecipes && recipes.count > recipesForMealType.count
    }

    // Group by protein type
    var groupedRecipes: [(protein: Recipe.ProteinType, recipes: [Recipe])] {
        let grouped = Dictionary(grouping: filteredRecipes, by: { $0.proteinType })
        return Recipe.ProteinType.allCases.compactMap { protein in
            guard let recipes = grouped[protein], !recipes.isEmpty else { return nil }
            return (protein: protein, recipes: recipes)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar at top
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search recipes", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Dish category filter
                if availableDishCategories.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            DishCategoryChip(
                                title: "All",
                                icon: "square.grid.2x2",
                                isSelected: selectedDishCategory == nil,
                                action: { selectedDishCategory = nil }
                            )

                            ForEach(availableDishCategories, id: \.self) { category in
                                DishCategoryChip(
                                    title: category.displayName,
                                    icon: category.iconName,
                                    isSelected: selectedDishCategory == category,
                                    action: { selectedDishCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }

                List {
                    // Quick options
                    Section {
                        Button {
                            showEatOutSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(.orange)
                                Text("Eat Out")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            showLeftoversSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "takeoutbag.and.cup.and.straw")
                                    .foregroundStyle(.green)
                                Text("Leftovers")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            showIngredientSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "carrot")
                                    .foregroundStyle(.purple)
                                Text("Add Ingredient")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } footer: {
                        Text("Use 'Add Ingredient' for standalone items like snacks or pre-packaged foods")
                    }

                    // Recipes grouped by protein type
                    if recipes.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "No Recipes",
                                systemImage: "book",
                                description: Text("Add recipes first to plan your meals")
                            )
                        }
                    } else if filteredRecipes.isEmpty {
                        Section {
                            if !searchText.isEmpty {
                                ContentUnavailableView.search(text: searchText)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: mealType.iconName)
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("No \(mealType.displayName) Recipes")
                                        .font(.headline)
                                    Text("You don't have any recipes categorized for \(mealType.displayName.lowercased()) yet")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                        }
                    } else {
                        ForEach(groupedRecipes, id: \.protein) { group in
                            Section(group.protein.displayName) {
                                ForEach(group.recipes) { recipe in
                                    Button {
                                        selectedRecipe = recipe
                                        showServingsSheet = true
                                    } label: {
                                        RecipeRowView(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Show All Recipes toggle
                    if hasOtherRecipes || showAllRecipes {
                        Section {
                            Toggle(isOn: $showAllRecipes) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle")
                                        .foregroundStyle(.blue)
                                    Text("Show All Recipes")
                                }
                            }
                        } footer: {
                            if !showAllRecipes {
                                Text("Showing only \(mealType.displayName.lowercased()) recipes. Toggle to see all.")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("\(mealType.displayName) - \(dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEatOutSheet) {
                TemplateEatOutSheet(
                    dayIndex: dayIndex,
                    restaurants: restaurants,
                    onAdd: { entry in
                        onAdd(entry)
                        pendingDismiss = true
                    }
                )
            }
            .sheet(isPresented: $showLeftoversSheet) {
                TemplateLeftoversSheet(
                    dayIndex: dayIndex,
                    mealType: mealType,
                    onAdd: { entry in
                        onAdd(entry)
                        pendingDismiss = true
                    }
                )
            }
            .sheet(isPresented: $showIngredientSheet) {
                TemplateIngredientSheet(
                    dayIndex: dayIndex,
                    mealType: mealType,
                    ingredients: ingredients,
                    onAdd: { entry in
                        onAdd(entry)
                        pendingDismiss = true
                    }
                )
            }
            .sheet(isPresented: $showServingsSheet) {
                if let recipe = selectedRecipe {
                    TemplateServingsSheet(
                        recipe: recipe,
                        dayIndex: dayIndex,
                        mealType: mealType,
                        onAdd: { entry in
                            onAdd(entry)
                            pendingDismiss = true
                        }
                    )
                }
            }
            .onChange(of: showEatOutSheet) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                }
            }
            .onChange(of: showLeftoversSheet) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                }
            }
            .onChange(of: showIngredientSheet) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                }
            }
            .onChange(of: showServingsSheet) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Template Eat Out Sheet

struct TemplateEatOutSheet: View {
    @Environment(\.dismiss) private var dismiss

    let dayIndex: Int
    let restaurants: [Restaurant]
    let onAdd: (MealPlanTemplate.TemplateEntry) -> Void

    @State private var selectedMealType: MealPlanEntry.MealType = .dinner
    @State private var selectedRestaurant: Restaurant?
    @State private var eatOutLocation = ""

    var canAdd: Bool {
        selectedRestaurant != nil || !eatOutLocation.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Meal", selection: $selectedMealType) {
                        ForEach(MealPlanEntry.MealType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }

                Section {
                    Picker("Restaurant", selection: $selectedRestaurant) {
                        Text("Custom location").tag(nil as Restaurant?)
                        ForEach(restaurants) { restaurant in
                            Text(restaurant.name).tag(restaurant as Restaurant?)
                        }
                    }

                    if selectedRestaurant == nil {
                        TextField("Location name", text: $eatOutLocation)
                    }
                } header: {
                    Text("Where")
                }
            }
            .navigationTitle("Eat Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let entry = MealPlanTemplate.TemplateEntry(
                            dayOfWeek: dayIndex,
                            mealType: selectedMealType,
                            isEatOut: true,
                            eatOutLocation: selectedRestaurant == nil ? eatOutLocation : nil,
                            restaurantId: selectedRestaurant?.id
                        )
                        onAdd(entry)
                        dismiss()
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Template Leftovers Sheet

struct TemplateLeftoversSheet: View {
    @Environment(\.dismiss) private var dismiss

    let dayIndex: Int
    let mealType: MealPlanEntry.MealType
    let onAdd: (MealPlanTemplate.TemplateEntry) -> Void

    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What leftovers? (optional)", text: $note)
                } footer: {
                    Text("Describe what leftovers you'll typically have")
                }
            }
            .navigationTitle("Leftovers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let entry = MealPlanTemplate.TemplateEntry(
                            dayOfWeek: dayIndex,
                            mealType: mealType,
                            isLeftovers: true,
                            leftoversNote: note.isEmpty ? nil : note
                        )
                        onAdd(entry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - Template Ingredient Sheet

struct TemplateIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss

    let dayIndex: Int
    let mealType: MealPlanEntry.MealType
    let ingredients: [IngredientPreference]
    let onAdd: (MealPlanTemplate.TemplateEntry) -> Void

    @State private var ingredientName = ""
    @State private var quantity = ""
    @State private var searchText = ""
    @State private var showExistingIngredients = true

    var filteredIngredients: [IngredientPreference] {
        if searchText.isEmpty {
            return ingredients
        }
        return ingredients.filter { $0.canonicalName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Quick add section
                Section {
                    TextField("Ingredient name", text: $ingredientName)
                    TextField("Quantity (e.g., 2 boxes, 1 lb)", text: $quantity)

                    Button {
                        addIngredient(name: ingredientName, quantity: quantity.isEmpty ? nil : quantity)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add to Template")
                                .foregroundStyle(.blue)
                        }
                    }
                    .disabled(ingredientName.isEmpty)
                } header: {
                    Text("Quick Add")
                } footer: {
                    Text("Enter any ingredient, snack, or pre-packaged item")
                }

                // Select from existing ingredients
                Section {
                    Toggle("Show saved ingredients", isOn: $showExistingIngredients)

                    if showExistingIngredients {
                        if ingredients.isEmpty {
                            Text("No saved ingredients yet")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else {
                            TextField("Search ingredients", text: $searchText)

                            ForEach(filteredIngredients.prefix(10)) { ingredient in
                                Button {
                                    addIngredient(name: ingredient.effectiveDisplayName, quantity: nil)
                                } label: {
                                    HStack {
                                        Text(ingredient.effectiveDisplayName)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if let store = ingredient.preferredStore {
                                            Text(store.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }

                            if filteredIngredients.count > 10 {
                                Text("\(filteredIngredients.count - 10) more...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Or Select Existing")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addIngredient(name: String, quantity: String?) {
        let entry = MealPlanTemplate.TemplateEntry(
            dayOfWeek: dayIndex,
            mealType: mealType,
            isIngredientOnly: true,
            ingredientName: name,
            ingredientQuantity: quantity
        )
        onAdd(entry)
        dismiss()
    }
}

// MARK: - Template Servings Sheet

struct TemplateServingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe
    let dayIndex: Int
    let mealType: MealPlanEntry.MealType
    let onAdd: (MealPlanTemplate.TemplateEntry) -> Void

    @State private var servings: Int
    @State private var useCustomServings = false

    init(recipe: Recipe, dayIndex: Int, mealType: MealPlanEntry.MealType, onAdd: @escaping (MealPlanTemplate.TemplateEntry) -> Void) {
        self.recipe = recipe
        self.dayIndex = dayIndex
        self.mealType = mealType
        self.onAdd = onAdd
        _servings = State(initialValue: recipe.baseServings)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(recipe.title)
                        .font(.headline)
                }

                Section {
                    Toggle("Adjust servings", isOn: $useCustomServings)

                    if useCustomServings {
                        Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    }
                } footer: {
                    Text("Base recipe makes \(recipe.baseServings) servings. Adjusting will scale grocery quantities.")
                }
            }
            .navigationTitle("Add to Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let entry = MealPlanTemplate.TemplateEntry(
                            dayOfWeek: dayIndex,
                            mealType: mealType,
                            recipeId: recipe.id,
                            servingsOverride: useCustomServings ? servings : nil
                        )
                        onAdd(entry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    CreateTemplateBuilderView(viewModel: MealPlanTemplatesViewModel())
}
