//
//  MoreView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
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

                // Shopping Section
                Section {
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
                    Text("Customize brands, stores, and shopping preferences for ingredients")
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

                NavigationLink {
                    PantryStaplesView()
                } label: {
                    Label("Pantry Staples", systemImage: "archivebox")
                }
            }

            // Support Section
            Section("Support") {
                NavigationLink {
                    FeedbackView()
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }

                NavigationLink {
                    FeedbackHistoryView()
                } label: {
                    Label("My Feedback", systemImage: "clock.arrow.circlepath")
                }
            }

            // App Section
            Section("App") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }

                if let url = URL(string: "https://mccall-family.github.io/mccall-home/privacy") {
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

            // Danger Zone
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
        .navigationTitle("Settings")
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

#Preview {
    MoreView()
        .environmentObject(AuthViewModel())
}
