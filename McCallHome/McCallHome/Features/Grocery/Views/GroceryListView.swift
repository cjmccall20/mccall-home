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
                    Button {
                        Task {
                            await viewModel.generateFromMealPlan()
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
                    Button {
                        showAddItem = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(viewModel.groceryList == nil)
                }
            }
            .task {
                await viewModel.fetchCurrentList()
            }
            .refreshable {
                await viewModel.fetchCurrentList()
            }
            .sheet(isPresented: $showAddItem) {
                addItemSheet
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

    private var progressHeader: some View {
        VStack(spacing: 8) {
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

            Text("Generate a grocery list from your meal plan for this week")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.generateFromMealPlan()
                }
            } label: {
                if viewModel.isGenerating {
                    ProgressView()
                        .padding(.horizontal)
                } else {
                    Label("Generate from Meal Plan", systemImage: "wand.and.stars")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isGenerating)

            Spacer()
        }
    }

    private var groceryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.groupedItems, id: \.category) { group in
                    GrocerySectionView(
                        category: group.category,
                        items: group.items,
                        onToggle: { item in
                            Task {
                                await viewModel.toggleItem(item)
                            }
                        },
                        onDelete: { item in
                            Task {
                                await viewModel.deleteItem(item)
                            }
                        }
                    )
                }
            }
        }
    }

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $newItemName)

                Picker("Category", selection: $newItemCategory) {
                    ForEach(GroceryItem.Category.allCases, id: \.self) { category in
                        Text(category.displayName)
                            .tag(category)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddItem = false
                        resetAddForm()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(newItemName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addItem() {
        Task {
            await viewModel.addManualItem(name: newItemName, category: newItemCategory)
            showAddItem = false
            resetAddForm()
        }
    }

    private func resetAddForm() {
        newItemName = ""
        newItemCategory = .other
    }
}

#Preview {
    GroceryListView()
}
