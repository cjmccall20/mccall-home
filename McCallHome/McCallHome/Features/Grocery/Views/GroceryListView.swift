//
//  GroceryListView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct GroceryListView: View {
    @StateObject private var viewModel = GroceryViewModel()
    @State private var showAddItem = false
    @State private var newItemName = ""
    @State private var newItemCategory: GroceryItem.Category = .other
    @State private var showClearOptions = false
    @State private var searchText = ""
    @State private var showDateRangePicker = false
    @State private var showInstacartOrder = false
    @State private var itemToEdit: GroceryItem?
    @State private var showCompleteConfirmation = false
    @State private var isCompletingShopping = false
    @State private var showRegenerateConfirmation = false
    @State private var pendingRegenerateAction: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress header
                if viewModel.totalCount > 0 {
                    progressHeader
                    Divider()
                }

                // Content
                Group {
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        Spacer()
                        ProgressView("Loading grocery list...")
                        Spacer()
                    } else if viewModel.groceryList == nil {
                        emptyStateView
                    } else if viewModel.items.isEmpty {
                        ContentUnavailableView(
                            "List is Empty",
                            systemImage: "cart",
                            description: Text("Generate a list from your meal plan or add items manually")
                        )
                    } else {
                        groceryList
                    }
                }
            }
            .navigationTitle("Grocery")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            if viewModel.checkedCount > 0 {
                                // Warn user about regenerating mid-shopping
                                pendingRegenerateAction = {
                                    viewModel.resetToCurrentWeek()
                                    Task {
                                        await viewModel.generateFromMealPlan()
                                    }
                                }
                                showRegenerateConfirmation = true
                            } else {
                                viewModel.resetToCurrentWeek()
                                Task {
                                    await viewModel.generateFromMealPlan()
                                }
                            }
                        } label: {
                            Label("This Week", systemImage: "calendar")
                        }

                        Button {
                            if viewModel.checkedCount > 0 {
                                pendingRegenerateAction = {
                                    showDateRangePicker = true
                                }
                                showRegenerateConfirmation = true
                            } else {
                                showDateRangePicker = true
                            }
                        } label: {
                            Label("Custom Range...", systemImage: "calendar.badge.clock")
                        }
                    } label: {
                        if viewModel.isGenerating {
                            ProgressView()
                        } else {
                            Label("Generate", systemImage: "wand.and.stars")
                        }
                    }
                    .disabled(viewModel.isGenerating)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Quick add button
                        Button {
                            showAddItem = true
                        } label: {
                            Image(systemName: "plus")
                        }

                        // Instacart button
                        if viewModel.uncheckedCount > 0 {
                            Button {
                                showInstacartOrder = true
                            } label: {
                                Image(systemName: "cart.badge.plus")
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Options menu
                        Menu {
                            Button {
                                showAddItem = true
                            } label: {
                                Label("Add Item", systemImage: "plus")
                            }

                            if viewModel.uncheckedCount > 0 {
                                Button {
                                    showInstacartOrder = true
                                } label: {
                                    Label("Send to Instacart", systemImage: "cart.badge.plus")
                                }
                            }

                            // Complete Shopping (show when there's progress)
                            if viewModel.checkedCount > 0 {
                                Divider()

                                Button {
                                    showCompleteConfirmation = true
                                } label: {
                                    Label("Complete Shopping", systemImage: "checkmark.circle.fill")
                                }
                            }

                            Divider()

                            if viewModel.checkedCount > 0 {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.clearCheckedItems()
                                    }
                                } label: {
                                    Label("Clear Checked (\(viewModel.checkedCount))", systemImage: "checkmark.circle")
                                }
                            }

                            if viewModel.totalCount > 0 {
                                Button(role: .destructive) {
                                    showClearOptions = true
                                } label: {
                                    Label("Clear All", systemImage: "trash")
                                }
                            }
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                        }
                    }
                    .disabled(viewModel.groceryList == nil)
                }
            }
            .task {
                await viewModel.fetchCurrentList()
                await viewModel.fetchPreviousItems()
            }
            .refreshable {
                await viewModel.fetchCurrentList()
            }
            .sheet(isPresented: $showAddItem) {
                AddGroceryItemView(viewModel: viewModel) {
                    showAddItem = false
                }
            }
            .sheet(isPresented: $showDateRangePicker) {
                DateRangePickerView(viewModel: viewModel) {
                    showDateRangePicker = false
                }
            }
            .sheet(isPresented: $showInstacartOrder) {
                InstacartOrderView(viewModel: viewModel)
            }
            .sheet(item: $itemToEdit) { item in
                GroceryItemEditView(
                    item: item,
                    ingredientPreference: IngredientPreferenceService.shared.findMatchingPreference(
                        for: item.name,
                        in: viewModel.ingredientPreferences
                    ),
                    onSave: { itemUpdate, prefUpdate in
                        Task {
                            await viewModel.updateItem(item, itemUpdate: itemUpdate, preferenceUpdate: prefUpdate)
                        }
                        itemToEdit = nil
                    },
                    onSubstitute: { newName in
                        Task {
                            await viewModel.substituteItem(item, with: newName)
                        }
                        itemToEdit = nil
                    }
                )
            }
            .alert("Clear All Items?", isPresented: $showClearOptions) {
                Button("Clear All", role: .destructive) {
                    Task {
                        await viewModel.clearAllItems()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all items from your grocery list.")
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
            .confirmationDialog("Complete Shopping?", isPresented: $showCompleteConfirmation, titleVisibility: .visible) {
                Button("Complete Shopping") {
                    isCompletingShopping = true
                    Task {
                        await viewModel.completeShopping()
                        isCompletingShopping = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will mark your shopping as complete and update all planned meals for this week as having ingredients. You can always generate a new list if needed.")
            }
            .confirmationDialog("Regenerate List?", isPresented: $showRegenerateConfirmation, titleVisibility: .visible) {
                Button("Keep Checked Items & Regenerate") {
                    // Smart merge - preserves checked items
                    pendingRegenerateAction?()
                    pendingRegenerateAction = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingRegenerateAction = nil
                }
            } message: {
                Text("You have \(viewModel.checkedCount) items already checked off. Regenerating will keep your purchased items and add any new items from your meal plan.")
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Generation info
            if let groceryList = viewModel.groceryList {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let dateRange = groceryList.formattedDateRange {
                            Text(dateRange)
                                .font(.headline)
                        }
                        if let generatedAt = groceryList.formattedGeneratedAt {
                            Text("Generated \(generatedAt)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            HStack {
                Text("\(viewModel.checkedCount) of \(viewModel.totalCount) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            ProgressView(value: viewModel.progress)
                .tint(.green)

            // Show Complete Shopping button when all items are checked
            if viewModel.progress == 1.0 && viewModel.totalCount > 0 {
                Button {
                    showCompleteConfirmation = true
                } label: {
                    HStack {
                        if isCompletingShopping {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Shopping")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isCompletingShopping)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.bar)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Grocery List")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Generate a grocery list from your meal plan")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    viewModel.resetToCurrentWeek()
                    Task {
                        await viewModel.generateFromMealPlan()
                    }
                } label: {
                    if viewModel.isGenerating {
                        ProgressView()
                            .padding(.horizontal)
                    } else {
                        Label("This Week", systemImage: "calendar")
                            .frame(minWidth: 200)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)

                Button {
                    showDateRangePicker = true
                } label: {
                    Label("Custom Date Range", systemImage: "calendar.badge.clock")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isGenerating)
            }

            Spacer()
        }
    }

    private var groceryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Group by source first
                ForEach(viewModel.groupedBySource, id: \.source) { sourceGroup in
                    Section {
                        ForEach(sourceGroup.categories, id: \.category) { categoryGroup in
                            GrocerySectionView(
                                category: categoryGroup.category,
                                items: categoryGroup.items,
                                ingredientPreferences: viewModel.ingredientPreferences,
                                onToggle: { item in
                                    Task {
                                        await viewModel.toggleItem(item)
                                    }
                                },
                                onDelete: { item in
                                    Task {
                                        await viewModel.deleteItem(item)
                                    }
                                },
                                onEdit: { item in
                                    itemToEdit = item
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Image(systemName: sourceGroup.source.iconName)
                                .font(.caption)
                            Text(sourceGroup.source.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(sourceGroup.source.backgroundColor)
                    }
                }
            }
        }
    }
}

// MARK: - Source Extensions

extension GroceryItem.Source {
    var iconName: String {
        switch self {
        case .mealPlan: return "book.closed"
        case .manual: return "hand.point.right"
        case .staple: return "star"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .mealPlan: return Color.blue.opacity(0.1)
        case .manual: return Color.orange.opacity(0.1)
        case .staple: return Color.purple.opacity(0.1)
        }
    }
}

// MARK: - Date Range Picker View

struct DateRangePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroceryViewModel
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $viewModel.startDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "End Date",
                        selection: $viewModel.endDate,
                        in: viewModel.startDate...,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("Select the date range for which to generate your grocery list from the meal plan.")
                }

                Section {
                    Button {
                        // Reset to current week
                        viewModel.resetToCurrentWeek()
                    } label: {
                        Text("Reset to Current Week")
                    }
                }

                Section {
                    HStack {
                        Text("Range")
                        Spacer()
                        Text(viewModel.dateRangeText)
                            .foregroundStyle(.secondary)
                    }

                    let dayCount = Calendar.current.dateComponents([.day], from: viewModel.startDate, to: viewModel.endDate).day ?? 0
                    HStack {
                        Text("Days")
                        Spacer()
                        Text("\(dayCount + 1) days")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Select Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Generate") {
                        viewModel.useCustomDateRange = true
                        Task {
                            await viewModel.generateFromMealPlan()
                            dismiss()
                            onComplete()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    GroceryListView()
}
