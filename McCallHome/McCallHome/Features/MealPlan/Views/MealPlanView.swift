//
//  MealPlanView.swift
//  McCallHome
//
//  Created by Claude on 11/30/25.
//

import SwiftUI

struct MealPlanView: View {
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var selectedDate: Date?
    @State private var selectedMealType: MealPlanEntry.MealType?
    @State private var showMealPicker = false
    @State private var showMealDetail = false
    @State private var showError = false
    @State private var showSaveTemplate = false
    @State private var showBrowseTemplates = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week navigation
                weekNavigationHeader

                Divider()

                // Week grid
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    Spacer()
                    ProgressView("Loading meal plan...")
                    Spacer()
                } else {
                    ScrollView {
                        weekGrid
                            .padding()
                    }
                }
            }
            .navigationTitle("Meal Plan")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showBrowseTemplates = true
                        } label: {
                            Label("Browse Saved Weeks", systemImage: "calendar.badge.clock")
                        }

                        if !viewModel.entries.isEmpty {
                            Button {
                                showSaveTemplate = true
                            } label: {
                                Label("Save This Week", systemImage: "square.and.arrow.down")
                            }
                        }
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        viewModel.goToCurrentWeek()
                    }
                    .disabled(viewModel.currentWeekStart == Calendar.current.startOfWeek(for: Date()))
                }
            }
            .task {
                await viewModel.fetchMealPlan()
            }
            .refreshable {
                await viewModel.fetchMealPlan()
            }
            .sheet(isPresented: $showMealPicker) {
                if let date = selectedDate, let mealType = selectedMealType {
                    MealPickerView(viewModel: viewModel, date: date, mealType: mealType)
                }
            }
            .sheet(isPresented: $showMealDetail) {
                if let date = selectedDate, let mealType = selectedMealType {
                    MealDetailView(viewModel: viewModel, date: date, mealType: mealType)
                }
            }
            .sheet(isPresented: $showSaveTemplate) {
                SaveTemplateSheet(mealPlanViewModel: viewModel)
            }
            .sheet(isPresented: $showBrowseTemplates) {
                MealPlanTemplatesView(
                    weekStart: viewModel.currentWeekStart,
                    onApply: {
                        Task {
                            await viewModel.fetchMealPlan()
                        }
                    }
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onChange(of: viewModel.error) { _, newError in
                // Only show error when no sheets are presented
                if newError != nil && !showMealPicker && !showMealDetail {
                    showError = true
                }
            }
        }
    }

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                viewModel.goToPreviousWeek()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text(viewModel.weekRangeText)
                .font(.headline)

            Spacer()

            Button {
                viewModel.goToNextWeek()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(.bar)
    }

    private var weekGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
            ForEach(viewModel.weekDays, id: \.self) { date in
                DayPlanView(
                    date: date,
                    viewModel: viewModel,
                    onEmptySlotTap: { mealType in
                        selectedDate = date
                        selectedMealType = mealType
                        showMealPicker = true
                    },
                    onFilledSlotTap: { mealType in
                        selectedDate = date
                        selectedMealType = mealType
                        showMealDetail = true
                    },
                    onAddDishTap: { mealType in
                        selectedDate = date
                        selectedMealType = mealType
                        showMealPicker = true
                    },
                    onRemove: { entry in
                        Task {
                            await viewModel.removeFromPlan(entry: entry)
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    MealPlanView()
}
