//
//  MoreView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI
import Combine

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    NavigationLink {
                        MyFavoritesView()
                    } label: {
                        Label {
                            HStack {
                                Text("My Favorites")
                                Spacer()
                                if let user = authViewModel.currentUser {
                                    Text(user.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                        }
                    }
                } header: {
                    Text("Profile")
                }

                // Dining Section
                Section {
                    NavigationLink {
                        RestaurantsListContent()
                    } label: {
                        Label {
                            Text("Restaurants")
                        } icon: {
                            Image(systemName: "fork.knife.circle")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Dining")
                }

                // Meal Planning Section
                Section {
                    NavigationLink {
                        SavedWeeksView()
                    } label: {
                        Label {
                            Text("Saved Weeks")
                        } icon: {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Meal Planning")
                } footer: {
                    Text("Save and reuse your favorite meal plan weeks")
                }

                // Shopping Section
                Section {
                    NavigationLink {
                        HouseStaplesView()
                    } label: {
                        Label {
                            Text("House Staples")
                        } icon: {
                            Image(systemName: "basket.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    NavigationLink {
                        PantryStaplesView()
                    } label: {
                        Label {
                            Text("Pantry Staples")
                        } icon: {
                            Image(systemName: "archivebox")
                                .foregroundStyle(.brown)
                        }
                    }

                    NavigationLink {
                        IngredientsListView()
                    } label: {
                        Label {
                            Text("Ingredients")
                        } icon: {
                            Image(systemName: "carrot")
                                .foregroundStyle(.green)
                        }
                    }
                } header: {
                    Text("Shopping")
                } footer: {
                    Text("Manage recurring grocery items and ingredient preferences")
                }

                // Settings Section
                Section {
                    NavigationLink {
                        SettingsContent()
                            .environmentObject(authViewModel)
                    } label: {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

// MARK: - Restaurants List Content (without NavigationStack)

struct RestaurantsListContent: View {
    @StateObject private var viewModel = RestaurantsViewModel()
    @State private var showAddRestaurant = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.restaurants.isEmpty {
                ProgressView("Loading restaurants...")
            } else if viewModel.restaurants.isEmpty {
                ContentUnavailableView(
                    "No Restaurants",
                    systemImage: "fork.knife.circle",
                    description: Text("Add your favorite restaurants to track orders and dishes")
                )
            } else {
                restaurantList
            }
        }
        .navigationTitle("Restaurants")
        .searchable(text: $viewModel.searchText, prompt: "Search restaurants")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddRestaurant = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.fetchRestaurants()
        }
        .refreshable {
            await viewModel.fetchRestaurants()
        }
        .sheet(isPresented: $showAddRestaurant) {
            AddRestaurantView(viewModel: viewModel)
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

    private var restaurantList: some View {
        List {
            // Favorites section
            if !viewModel.favoriteRestaurants.isEmpty {
                Section("Favorites") {
                    ForEach(viewModel.favoriteRestaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant, viewModel: viewModel)
                        } label: {
                            RestaurantRowView(restaurant: restaurant)
                        }
                    }
                }
            }

            // Grouped by cuisine
            ForEach(viewModel.groupedByCuisine, id: \.cuisine) { group in
                Section(group.cuisine.displayName) {
                    ForEach(group.restaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurant: restaurant, viewModel: viewModel)
                        } label: {
                            RestaurantRowView(restaurant: restaurant)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteRestaurant(restaurant)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await viewModel.toggleFavorite(restaurant)
                                }
                            } label: {
                                Label(
                                    restaurant.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: restaurant.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            .tint(.pink)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Settings Content (without NavigationStack)

struct SettingsContent: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var memberService = SettingsMemberService()
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false

    var body: some View {
        List {
            // Profile Section
            Section("Profile") {
                NavigationLink {
                    ProfileView()
                        .environmentObject(authViewModel)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            if let user = authViewModel.currentUser {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Loading...")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Household Section
            Section("Household") {
                NavigationLink {
                    HouseholdMembersView()
                } label: {
                    Label("Household Members", systemImage: "person.2")
                }

                NavigationLink {
                    HouseholdSettingsView()
                } label: {
                    Label("Household Settings", systemImage: "house")
                }

                NavigationLink {
                    InvitationsView()
                } label: {
                    Label("Invite Members", systemImage: "person.badge.plus")
                }
            }

            // Support Section
            Section("Support") {
                NavigationLink {
                    FeedbackView()
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }
            }

            // App Section
            Section("App") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }

                if let url = URL(string: "https://cjmccall20.github.io/mccall-home/privacy/") {
                    Link(destination: url) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }

            // Sign Out
            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }

            // Danger Zone - Only visible to household owner
            if memberService.isOwner {
                Section {
                    Button(role: .destructive) {
                        showDeleteAccountConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Account", systemImage: "trash")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Permanently delete your account and all associated data. This cannot be undone.")
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await memberService.checkOwnerStatus()
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account", role: .destructive) {
                Task {
                    await authViewModel.deleteAccount()
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }
}

// MARK: - Settings Member Service

@MainActor
class SettingsMemberService: ObservableObject {
    @Published var isOwner: Bool = false

    func checkOwnerStatus() async {
        // In dev mode, always return true for testing
        if Config.skipAuthForDevelopment {
            isOwner = true
            return
        }

        guard let householdId = AuthService.shared.currentUser?.householdId,
              let currentUserName = AuthService.shared.currentUser?.name else {
            isOwner = false
            return
        }

        do {
            let members = try await HouseholdMemberService.shared.fetchMembers(for: householdId)
            isOwner = members.first { $0.name == currentUserName }?.isOwner ?? false
        } catch {
            isOwner = false
        }
    }
}

#Preview {
    MoreView()
        .environmentObject(AuthViewModel())
}
