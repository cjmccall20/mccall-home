//
//  MealPickerView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct MealPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MealPlanViewModel

    let date: Date
    let mealType: MealPlanEntry.MealType

    @State private var searchText = ""
    @State private var showEatOutSheet = false
    @State private var showLeftoversSheet = false
    @State private var selectedRecipe: Recipe?
    @State private var showServingsSheet = false
    @State private var showAllRecipes = false

    // Track if we should dismiss after a child sheet closes
    @State private var pendingDismiss = false

    // Recipes that match the meal category (breakfast/lunch/dinner)
    var recipesForMealType: [Recipe] {
        if showAllRecipes {
            return viewModel.recipes
        }
        return viewModel.recipes.filter { $0.mealCategory.matches(mealType) }
    }

    // Further filter by search text
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipesForMealType
        }
        return recipesForMealType.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Recipes from other categories (shown when "Show All" is off)
    var hasOtherRecipes: Bool {
        !showAllRecipes && viewModel.recipes.count > recipesForMealType.count
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

                List {
                    // Quick options (Eat Out, Leftovers)
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
                    }

                    // Recipes grouped by protein type
                    if viewModel.recipes.isEmpty {
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
                                    Image(systemName: mealType == .breakfast ? "sunrise" : mealType == .lunch ? "sun.max" : "moon.stars")
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
            .navigationTitle("\(mealType.displayName) - \(date.shortDateString)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEatOutSheet) {
                EatOutSheet(date: date, mealType: mealType, viewModel: viewModel) {
                    pendingDismiss = true
                }
            }
            .sheet(isPresented: $showLeftoversSheet) {
                LeftoversSheet(date: date, mealType: mealType, viewModel: viewModel) {
                    pendingDismiss = true
                }
            }
            .sheet(isPresented: $showServingsSheet) {
                if let recipe = selectedRecipe {
                    ServingsSheet(recipe: recipe, date: date, mealType: mealType, viewModel: viewModel) {
                        pendingDismiss = true
                    }
                }
            }
            // Wait for child sheets to fully dismiss before dismissing self
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
            .onChange(of: showServingsSheet) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Eat Out Sheet

struct EatOutSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let mealType: MealPlanEntry.MealType
    @ObservedObject var viewModel: MealPlanViewModel
    let onComplete: () -> Void

    enum AccordionSection: String, CaseIterable {
        case selectRestaurant = "Select Restaurant"
        case quickNote = "Quick Note"
        case addRestaurant = "Add New Restaurant"

        var icon: String {
            switch self {
            case .selectRestaurant: return "fork.knife"
            case .quickNote: return "pencil"
            case .addRestaurant: return "plus.circle"
            }
        }

        var iconColor: Color {
            switch self {
            case .selectRestaurant: return .orange
            case .quickNote: return .blue
            case .addRestaurant: return .green
            }
        }
    }

    @State private var expandedSection: AccordionSection? = .selectRestaurant
    @State private var quickNote = ""
    @State private var isAdding = false

    // Restaurant selection
    @State private var selectedRestaurant: Restaurant?
    @State private var showRestaurantPicker = false
    @State private var showOrderSelection = false

    // New restaurant
    @State private var showAddRestaurant = false

    // Track if we should dismiss after child sheet closes
    @State private var pendingDismiss = false

    var body: some View {
        NavigationStack {
            List {
                // Select Restaurant accordion
                Section {
                    accordionHeader(for: .selectRestaurant)
                    if expandedSection == .selectRestaurant {
                        if let restaurant = selectedRestaurant {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(restaurant.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(restaurant.cuisineType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Change") {
                                    showRestaurantPicker = true
                                }
                                .font(.subheadline)
                            }
                            .padding(.leading, 28)

                            Button {
                                showOrderSelection = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Continue to Select Orders")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.leading, 28)
                        } else {
                            Button {
                                showRestaurantPicker = true
                            } label: {
                                HStack {
                                    Text("Choose a restaurant...")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.leading, 28)

                            if viewModel.restaurants.isEmpty {
                                Text("No restaurants saved yet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 28)
                            }
                        }
                    }
                }

                // Quick Note accordion
                Section {
                    accordionHeader(for: .quickNote)
                    if expandedSection == .quickNote {
                        TextField("Restaurant or note", text: $quickNote)
                            .padding(.leading, 28)

                        Button {
                            addQuickNote()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Add to Plan")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .disabled(isAdding)
                        .padding(.leading, 28)
                    }
                }

                // Add New Restaurant accordion
                Section {
                    accordionHeader(for: .addRestaurant)
                    if expandedSection == .addRestaurant {
                        Button {
                            showAddRestaurant = true
                        } label: {
                            HStack {
                                Text("Create new restaurant...")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.leading, 28)

                        Text("Restaurant will be added to your collection and used for this meal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 28)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Eat Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRestaurantPicker) {
                RestaurantPickerSheet(
                    restaurants: viewModel.restaurants,
                    onSelect: { restaurant in
                        selectedRestaurant = restaurant
                    }
                )
            }
            .sheet(isPresented: $showOrderSelection) {
                if let restaurant = selectedRestaurant {
                    OrderSelectionSheet(
                        restaurant: restaurant,
                        date: date,
                        mealType: mealType,
                        viewModel: viewModel,
                        onComplete: {
                            pendingDismiss = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showAddRestaurant) {
                AddRestaurantForMealSheet(
                    date: date,
                    mealType: mealType,
                    viewModel: viewModel,
                    onComplete: {
                        pendingDismiss = true
                    }
                )
            }
            // Wait for child sheets to fully dismiss before dismissing self
            .onChange(of: showOrderSelection) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                    onComplete()
                }
            }
            .onChange(of: showAddRestaurant) { _, isShowing in
                if !isShowing && pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                    onComplete()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isAdding)
    }

    @ViewBuilder
    private func accordionHeader(for section: AccordionSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if expandedSection == section {
                    expandedSection = nil
                } else {
                    expandedSection = section
                }
            }
        } label: {
            HStack {
                Image(systemName: section.icon)
                    .foregroundStyle(section.iconColor)
                    .frame(width: 24)
                Text(section.rawValue)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: expandedSection == section ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private func addQuickNote() {
        guard !isAdding else { return }
        isAdding = true
        Task {
            await viewModel.addEatOut(
                to: date,
                mealType: mealType,
                location: quickNote.isEmpty ? nil : quickNote
            )
            dismiss()
            onComplete()
        }
    }
}

// MARK: - Restaurant Picker Sheet

struct RestaurantPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let restaurants: [Restaurant]
    let onSelect: (Restaurant) -> Void

    @State private var searchText = ""

    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty {
            return restaurants
        }
        return restaurants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var groupedRestaurants: [(cuisine: Restaurant.CuisineType, restaurants: [Restaurant])] {
        let grouped = Dictionary(grouping: filteredRestaurants, by: { $0.cuisineType })
        return Restaurant.CuisineType.allCases.compactMap { cuisine in
            guard let list = grouped[cuisine], !list.isEmpty else { return nil }
            return (cuisine: cuisine, restaurants: list.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if restaurants.isEmpty {
                    ContentUnavailableView(
                        "No Restaurants",
                        systemImage: "fork.knife",
                        description: Text("Add restaurants from the Restaurants tab first")
                    )
                } else if filteredRestaurants.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(groupedRestaurants, id: \.cuisine) { group in
                        Section(group.cuisine.displayName) {
                            ForEach(group.restaurants) { restaurant in
                                Button {
                                    onSelect(restaurant)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(restaurant.name)
                                                .foregroundStyle(.primary)
                                            if let address = restaurant.address, !address.isEmpty {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if restaurant.isFavorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search restaurants")
            .navigationTitle("Select Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Order Selection Sheet

struct OrderSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    let date: Date
    let mealType: MealPlanEntry.MealType
    @ObservedObject var viewModel: MealPlanViewModel
    let onComplete: () -> Void

    @State private var orders: [RestaurantOrder] = []
    @State private var selectedOrderIds: Set<UUID> = []
    @State private var note = ""
    @State private var isLoading = true
    @State private var isAdding = false
    @State private var showAddOrder = false
    @State private var householdMembers: [HouseholdMember] = []

    var ordersByMember: [(member: HouseholdMember?, orders: [RestaurantOrder])] {
        var result: [(member: HouseholdMember?, orders: [RestaurantOrder])] = []

        // Group orders by member
        let memberOrders = Dictionary(grouping: orders.filter { $0.householdMemberId != nil }) { $0.householdMemberId! }

        // Add orders for each member
        for member in householdMembers {
            if let memberOrderList = memberOrders[member.id], !memberOrderList.isEmpty {
                result.append((member: member, orders: memberOrderList))
            }
        }

        // Add orders without a member
        let unassignedOrders = orders.filter { $0.householdMemberId == nil }
        if !unassignedOrders.isEmpty {
            result.append((member: nil, orders: unassignedOrders))
        }

        return result
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(restaurant.name)
                                .font(.headline)
                            Text(restaurant.cuisineType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if orders.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "list.clipboard")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No saved orders")
                                .font(.headline)
                            Text("Add an order to remember what everyone likes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    ForEach(ordersByMember, id: \.member?.id) { group in
                        Section(group.member?.name ?? "Unassigned") {
                            ForEach(group.orders) { order in
                                OrderSelectionRow(
                                    order: order,
                                    isSelected: selectedOrderIds.contains(order.id),
                                    onToggle: {
                                        if selectedOrderIds.contains(order.id) {
                                            selectedOrderIds.remove(order.id)
                                        } else {
                                            selectedOrderIds.insert(order.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showAddOrder = true
                    } label: {
                        Label("Add New Order", systemImage: "plus")
                    }
                }

                Section {
                    TextField("Additional notes (optional)", text: $note)
                } footer: {
                    Text("Add any special instructions or notes")
                }
            }
            .navigationTitle("Select Orders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add to Plan") {
                        addToPlan()
                    }
                    .disabled(isAdding)
                    .fontWeight(.semibold)
                }
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showAddOrder) {
                QuickAddOrderSheet(
                    restaurant: restaurant,
                    householdMembers: householdMembers,
                    viewModel: viewModel,
                    onOrderAdded: { newOrder in
                        orders.append(newOrder)
                        selectedOrderIds.insert(newOrder.id)
                    }
                )
            }
        }
    }

    private func loadData() async {
        isLoading = true
        orders = await viewModel.fetchOrders(for: restaurant.id)

        // Fetch household members
        if let householdId = viewModel.householdId {
            do {
                householdMembers = try await HouseholdMemberService.shared.fetchMembers(for: householdId)
            } catch {
                // Silently fail - members just won't be grouped
            }
        }

        isLoading = false
    }

    private func addToPlan() {
        guard !isAdding else { return }
        isAdding = true
        Task {
            await viewModel.addEatOutWithRestaurant(
                to: date,
                mealType: mealType,
                restaurantId: restaurant.id,
                orderIds: Array(selectedOrderIds),
                note: note.isEmpty ? nil : note
            )
            dismiss()
            onComplete()
        }
    }
}

// MARK: - Order Selection Row

struct OrderSelectionRow: View {
    let order: RestaurantOrder
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if !order.items.isEmpty {
                        Text(order.items.map { $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if let rating = order.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(rating)")
                    }
                    .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Add Order Sheet

struct QuickAddOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    let householdMembers: [HouseholdMember]
    @ObservedObject var viewModel: MealPlanViewModel
    let onOrderAdded: (RestaurantOrder) -> Void

    @State private var selectedMemberId: UUID?
    @State private var orderName = ""
    @State private var itemName = ""
    @State private var items: [RestaurantOrder.OrderItem] = []
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Person", selection: $selectedMemberId) {
                        Text("Unassigned").tag(nil as UUID?)
                        ForEach(householdMembers) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }

                    TextField("Order Name (e.g., 'Usual Order')", text: $orderName)
                }

                Section("Items") {
                    ForEach(items) { item in
                        Text(item.name)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Add item", text: $itemName)
                        Button {
                            if !itemName.isEmpty {
                                items.append(RestaurantOrder.OrderItem(name: itemName))
                                itemName = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(itemName.isEmpty)
                    }
                }
            }
            .navigationTitle("Add Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveOrder()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveOrder() {
        guard let householdId = viewModel.householdId else { return }
        isSaving = true

        let order = RestaurantOrder(
            restaurantId: restaurant.id,
            householdId: householdId,
            householdMemberId: selectedMemberId,
            orderName: orderName.isEmpty ? nil : orderName,
            items: items
        )

        Task {
            do {
                try await RestaurantService.shared.createOrder(order)
                onOrderAdded(order)
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}

// MARK: - Add Restaurant For Meal Sheet

struct AddRestaurantForMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let mealType: MealPlanEntry.MealType
    @ObservedObject var viewModel: MealPlanViewModel
    let onComplete: () -> Void

    @State private var name = ""
    @State private var cuisineType: Restaurant.CuisineType = .other
    @State private var address = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Restaurant Name", text: $name)

                    Picker("Cuisine", selection: $cuisineType) {
                        ForEach(Restaurant.CuisineType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    TextField("Address (optional)", text: $address)
                }
            }
            .navigationTitle("New Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add to Plan") {
                        saveAndAdd()
                    }
                    .disabled(name.isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveAndAdd() {
        guard let householdId = viewModel.householdId else { return }
        isSaving = true

        let restaurant = Restaurant(
            householdId: householdId,
            name: name,
            cuisineType: cuisineType,
            address: address.isEmpty ? nil : address
        )

        Task {
            do {
                try await RestaurantService.shared.createRestaurant(restaurant)
                await viewModel.addEatOutWithRestaurant(
                    to: date,
                    mealType: mealType,
                    restaurantId: restaurant.id,
                    orderIds: [],
                    note: nil
                )
                dismiss()
                onComplete()
            } catch {
                isSaving = false
            }
        }
    }
}

// MARK: - Leftovers Sheet

struct LeftoversSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let mealType: MealPlanEntry.MealType
    @ObservedObject var viewModel: MealPlanViewModel
    let onComplete: () -> Void

    @State private var note = ""
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What leftovers? (optional)", text: $note)
                } footer: {
                    Text("Add a note about what you're having")
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
                        guard !isAdding else { return }
                        isAdding = true
                        Task {
                            await viewModel.addLeftovers(
                                to: date,
                                mealType: mealType,
                                note: note.isEmpty ? nil : note
                            )
                            dismiss()
                            onComplete()
                        }
                    }
                    .disabled(isAdding)
                }
            }
        }
        .presentationDetents([.height(200)])
        .interactiveDismissDisabled(isAdding)
    }
}

// MARK: - Servings Sheet

struct ServingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    let date: Date
    let mealType: MealPlanEntry.MealType
    @ObservedObject var viewModel: MealPlanViewModel
    let onComplete: () -> Void

    @State private var servings: Int
    @State private var useCustomServings = false
    @State private var isAdding = false

    init(recipe: Recipe, date: Date, mealType: MealPlanEntry.MealType, viewModel: MealPlanViewModel, onComplete: @escaping () -> Void) {
        self.recipe = recipe
        self.date = date
        self.mealType = mealType
        self.viewModel = viewModel
        self.onComplete = onComplete
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
            .navigationTitle("Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        guard !isAdding else { return }
                        isAdding = true
                        Task {
                            await viewModel.assignRecipe(
                                recipe,
                                to: date,
                                mealType: mealType,
                                servings: useCustomServings ? servings : nil
                            )
                            dismiss()
                            onComplete()
                        }
                    }
                    .disabled(isAdding)
                }
            }
        }
        .presentationDetents([.height(300)])
        .interactiveDismissDisabled(isAdding)
    }
}

// MARK: - Date Extension

extension Date {
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

#Preview {
    MealPickerView(
        viewModel: MealPlanViewModel(),
        date: Date(),
        mealType: .dinner
    )
}
