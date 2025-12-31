//
//  SavedWeeksView.swift
//  McCallHome
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

/// View for managing saved meal plan weeks (templates)
/// This is a standalone view for the More tab (without dismiss functionality)
struct SavedWeeksView: View {
    @StateObject private var viewModel = MealPlanTemplatesViewModel()
    @State private var showCreateTemplate = false

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if viewModel.templates.isEmpty && viewModel.rotations.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("No Saved Weeks")
                            .font(.headline)

                        Text("Save a week from your meal plan to reuse it later. Go to the Food tab, set up your meal plan, then tap the menu to save the current week.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                // Saved weeks section
                if !viewModel.templates.isEmpty {
                    Section {
                        ForEach(viewModel.templates) { template in
                            SavedWeekRow(
                                template: template,
                                recipes: viewModel.recipes,
                                restaurants: viewModel.restaurants,
                                ingredients: viewModel.ingredients,
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
                        Text("Tap to view details. These weeks can be applied from the meal plan view.")
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
                        Text("When active, rotation schedules automatically advance to the next week in the sequence")
                    }
                }
            }

            // Help section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to save a week")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Go to Food > Meal Plan, set up your week, then tap the menu button and select \"Save This Week\"")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "1.circle.fill")
                            .foregroundStyle(.blue)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to use a saved week")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Go to Food > Meal Plan, tap the menu button, select \"Load Saved Week\", then choose the week you want to apply")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "2.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Quick Guide")
            }
        }
        .navigationTitle("Saved Weeks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showCreateTemplate) {
            CreateTemplateBuilderView(viewModel: viewModel)
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

// MARK: - Saved Week Row

struct SavedWeekRow: View {
    let template: MealPlanTemplate
    let recipes: [Recipe]
    let restaurants: [Restaurant]
    let ingredients: [IngredientPreference]
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
                ingredients: ingredients,
                weekStart: nil,
                onApply: {}
                // onSave not provided - edit not available from More tab
            )
        }
    }
}

#Preview {
    NavigationStack {
        SavedWeeksView()
    }
}
