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
                        Text("Swipe left to remove a dish")
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
    }
}

#Preview {
    MealDetailView(
        viewModel: MealPlanViewModel(),
        date: Date(),
        mealType: .dinner
    )
}
