//
//  PantryStaplesView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI
import Supabase

struct PantryStaplesView: View {
    @State private var staples: [PantryStaple] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showAddStaple = false
    @State private var newStapleName = ""
    @State private var newStapleCategory = ""

    private let authService = AuthService.shared

    var groupedStaples: [(category: String, items: [PantryStaple])] {
        let grouped = Dictionary(grouping: staples, by: { $0.category ?? "Other" })
        return grouped.sorted { $0.key < $1.key }
            .map { (category: $0.key, items: $0.value) }
    }

    var body: some View {
        Group {
            if isLoading && staples.isEmpty {
                ProgressView("Loading staples...")
            } else if staples.isEmpty {
                ContentUnavailableView(
                    "No Pantry Staples",
                    systemImage: "archivebox",
                    description: Text("Add items you always keep stocked")
                )
            } else {
                List {
                    ForEach(groupedStaples, id: \.category) { group in
                        Section(group.category) {
                            ForEach(group.items) { staple in
                                Text(staple.name)
                            }
                            .onDelete { indexSet in
                                deleteStaples(in: group.items, at: indexSet)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pantry Staples")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddStaple = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await fetchStaples()
        }
        .refreshable {
            await fetchStaples()
        }
        .sheet(isPresented: $showAddStaple) {
            addStapleSheet
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

    private var addStapleSheet: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $newStapleName)

                TextField("Category (e.g., Spices, Oils)", text: $newStapleCategory)
            }
            .navigationTitle("Add Staple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddStaple = false
                        resetForm()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addStaple()
                    }
                    .disabled(newStapleName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func fetchStaples() async {
        guard let householdId = authService.currentUser?.householdId else { return }

        isLoading = true
        error = nil

        do {
            let response: [PantryStaple] = try await supabase
                .from("pantry_staples")
                .select()
                .eq("household_id", value: householdId.uuidString)
                .order("name", ascending: true)
                .execute()
                .value

            staples = response
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func addStaple() {
        guard let householdId = authService.currentUser?.householdId else { return }

        let staple = PantryStaple(
            id: UUID(),
            householdId: householdId,
            name: newStapleName,
            category: newStapleCategory.isEmpty ? nil : newStapleCategory,
            createdAt: Date()
        )

        Task {
            do {
                try await supabase
                    .from("pantry_staples")
                    .insert(staple)
                    .execute()

                await fetchStaples()
                showAddStaple = false
                resetForm()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func deleteStaples(in items: [PantryStaple], at indexSet: IndexSet) {
        for index in indexSet {
            let staple = items[index]
            Task {
                do {
                    try await supabase
                        .from("pantry_staples")
                        .delete()
                        .eq("id", value: staple.id.uuidString)
                        .execute()

                    await fetchStaples()
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func resetForm() {
        newStapleName = ""
        newStapleCategory = ""
    }
}

#Preview {
    NavigationStack {
        PantryStaplesView()
    }
}
