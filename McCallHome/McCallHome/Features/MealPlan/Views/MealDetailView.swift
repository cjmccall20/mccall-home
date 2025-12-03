//
//  MealDetailView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MealPlanViewModel

    let date: Date
    let mealType: MealPlanEntry.MealType

    @State private var showAddDish = false
    @State private var selectedRecipe: Recipe?
    @State private var entryToReschedule: MealPlanEntry?

    var entries: [MealPlanEntry] {
        viewModel.entries(for: date, mealType: mealType)
    }

    var body: some View {
        NavigationStack {
            List {
                // Current dishes
                Section {
                    if entries.isEmpty {
                        Text("No dishes planned")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(entries) { entry in
                            entryRow(entry)
                        }
                    }
                } header: {
                    Text("Dishes")
                } footer: {
                    if !entries.isEmpty {
                        Text("Swipe left to remove, swipe right to toggle groceries status")
                    }
                }

                // Add dish button
                Section {
                    Button {
                        showAddDish = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add Dish")
                                .foregroundStyle(.primary)
                        }
                    }

                    // Reschedule option (only show when there are entries)
                    if !entries.isEmpty {
                        Menu {
                            ForEach(entries) { entry in
                                Button {
                                    entryToReschedule = entry
                                } label: {
                                    Text(viewModel.displayText(for: entry))
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(.blue)
                                Text("Reschedule Dish")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(mealType.displayName) - \(date.shortDateString)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddDish) {
                MealPickerView(viewModel: viewModel, date: date, mealType: mealType)
            }
            .sheet(item: $selectedRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe, viewModel: RecipesViewModel())
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") {
                                    selectedRecipe = nil
                                }
                            }
                        }
                }
            }
            .sheet(item: $entryToReschedule) { entry in
                RescheduleMealSheet(
                    entry: entry,
                    viewModel: viewModel
                )
            }
        }
    }

    @ViewBuilder
    private func groceryStatusIcon(for entry: MealPlanEntry) -> some View {
        if entry.hasIngredients || entry.shoppedAt != nil {
            // Has ingredients or already shopped
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        } else {
            // Needs groceries
            Image(systemName: "cart.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: MealPlanEntry) -> some View {
        HStack {
            if entry.isEatOut {
                Image(systemName: "fork.knife")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text("Eat Out")
                        .font(.body)
                    if let location = entry.eatOutLocation, !location.isEmpty {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if entry.isLeftovers {
                Image(systemName: "takeoutbag.and.cup.and.straw")
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("Leftovers")
                        .font(.body)
                    if let note = entry.leftoversNote, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if entry.isIngredientOnly {
                Image(systemName: "carrot")
                    .foregroundStyle(.purple)
                VStack(alignment: .leading) {
                    Text(entry.ingredientName ?? "Ingredient")
                        .font(.body)
                    if let quantity = entry.ingredientQuantity, !quantity.isEmpty {
                        Text(quantity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                groceryStatusIcon(for: entry)
            } else if let recipe = viewModel.recipe(for: entry) {
                Image(systemName: recipe.dishCategory.iconName)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text(recipe.title)
                        .font(.body)
                    if let servings = entry.servingsOverride {
                        Text("\(servings) servings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                groceryStatusIcon(for: entry)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let recipe = viewModel.recipe(for: entry) {
                selectedRecipe = recipe
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    await viewModel.removeFromPlan(entry: entry)
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                Task {
                    await viewModel.toggleHasIngredients(for: entry)
                }
            } label: {
                Label(
                    entry.hasIngredients ? "Need Groceries" : "Have Ingredients",
                    systemImage: entry.hasIngredients ? "cart.badge.minus" : "checkmark.circle"
                )
            }
            .tint(entry.hasIngredients ? .orange : .green)
        }
    }
}

// MARK: - Reschedule Meal Sheet

struct RescheduleMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: MealPlanEntry
    @ObservedObject var viewModel: MealPlanViewModel

    @State private var newDate: Date
    @State private var newMealType: MealPlanEntry.MealType
    @State private var hasIngredients: Bool
    @State private var isRescheduling = false

    init(entry: MealPlanEntry, viewModel: MealPlanViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        _newDate = State(initialValue: entry.scheduledDate)
        _newMealType = State(initialValue: entry.mealType)
        _hasIngredients = State(initialValue: entry.hasIngredients)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Show what meal we're rescheduling
                    HStack {
                        Text("Meal")
                        Spacer()
                        Text(viewModel.displayText(for: entry))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("New Date & Time") {
                    DatePicker(
                        "Date",
                        selection: $newDate,
                        displayedComponents: .date
                    )

                    Picker("Meal", selection: $newMealType) {
                        ForEach(MealPlanEntry.MealType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section {
                    Toggle(isOn: $hasIngredients) {
                        VStack(alignment: .leading) {
                            Text("I already have the ingredients")
                            Text("Skip adding to grocery list")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Enable this if you already have all the ingredients for this meal and don't need them added to your grocery list.")
                }
            }
            .navigationTitle("Reschedule Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        reschedule()
                    }
                    .disabled(isRescheduling)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isRescheduling)
    }

    private func reschedule() {
        isRescheduling = true
        Task {
            await viewModel.rescheduleMeal(
                entry,
                to: newDate,
                newMealType: newMealType != entry.mealType ? newMealType : nil,
                hasIngredients: hasIngredients
            )
            dismiss()
        }
    }
}

#Preview {
    MealDetailView(
        viewModel: MealPlanViewModel(),
        date: Date(),
        mealType: .dinner
    )
}
