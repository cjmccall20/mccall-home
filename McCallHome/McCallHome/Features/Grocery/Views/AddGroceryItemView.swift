//
//  AddGroceryItemView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct AddGroceryItemView: View {
    @ObservedObject var viewModel: GroceryViewModel
    let onDismiss: () -> Void

    @State private var itemName = ""
    @State private var selectedCategory: GroceryItem.Category = .other
    @State private var searchResults: [PreviousGroceryItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search/Add field
                Form {
                    Section {
                        TextField("Item name", text: $itemName)
                            .onChange(of: itemName) { _, newValue in
                                searchPreviousItems(query: newValue)
                            }

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(GroceryItem.Category.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }

                        Button {
                            addNewItem()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Add Item")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(itemName.isEmpty)
                    }
                }
                .frame(maxHeight: 200)

                Divider()

                // Previous items / Search results
                if !itemName.isEmpty && !searchResults.isEmpty {
                    List {
                        Section("Matching Previous Items") {
                            ForEach(searchResults) { item in
                                Button {
                                    addFromPrevious(item)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .foregroundStyle(.primary)
                                            Text(item.category.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if !viewModel.previousItems.isEmpty && itemName.isEmpty {
                    List {
                        Section("Recent Items") {
                            ForEach(viewModel.previousItems.prefix(10)) { item in
                                Button {
                                    addFromPrevious(item)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .foregroundStyle(.primary)
                                            HStack(spacing: 8) {
                                                Text(item.category.displayName)
                                                Text("Used \(item.timesUsed)x")
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }

    private func searchPreviousItems(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        Task {
            searchResults = await viewModel.searchPreviousItems(query: query)
        }
    }

    private func addNewItem() {
        Task {
            await viewModel.addManualItem(name: itemName, category: selectedCategory)
            onDismiss()
        }
    }

    private func addFromPrevious(_ item: PreviousGroceryItem) {
        Task {
            await viewModel.addFromPreviousItem(item)
            onDismiss()
        }
    }
}

#Preview {
    AddGroceryItemView(viewModel: GroceryViewModel()) {}
}
