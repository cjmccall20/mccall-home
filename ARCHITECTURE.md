# McCallHome iOS App Architecture

## Overview

McCallHome is a family household management iOS app built with SwiftUI and Supabase backend.

## Project Structure

```
McCallHome/
├── McCallHomeApp.swift          # App entry point with auth flow
├── MainTabView.swift            # Main tab navigation
├── Config.swift                 # Configuration (Supabase URL, keys)
├── SupabaseClient.swift         # Supabase client singleton
├── Core/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Household.swift
│   │   ├── HoneydewTask.swift
│   │   ├── Recipe.swift
│   │   ├── MealPlanEntry.swift
│   │   ├── GroceryList.swift
│   │   ├── GroceryItem.swift
│   │   ├── PantryStaple.swift
│   │   └── CalendarEvent.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── TaskService.swift
│   │   ├── RecipeService.swift
│   │   ├── MealPlanService.swift
│   │   └── GroceryService.swift
│   └── Extensions/
│       └── Date+Extensions.swift
├── Features/
│   ├── Auth/
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift
│   │   └── Views/
│   │       ├── AuthContainerView.swift
│   │       ├── LoginView.swift
│   │       └── SignUpView.swift
│   ├── Honeydew/
│   │   ├── ViewModels/
│   │   │   └── HoneydewViewModel.swift
│   │   └── Views/
│   │       ├── HoneydewListView.swift
│   │       ├── HoneydewRowView.swift
│   │       ├── TaskDetailView.swift
│   │       └── CreateTaskView.swift
│   ├── Recipes/
│   │   ├── ViewModels/
│   │   │   └── RecipesViewModel.swift
│   │   └── Views/
│   │       ├── RecipeListView.swift
│   │       ├── RecipeRowView.swift
│   │       ├── RecipeDetailView.swift
│   │       └── CreateRecipeView.swift
│   ├── MealPlan/
│   │   ├── ViewModels/
│   │   │   └── MealPlanViewModel.swift
│   │   └── Views/
│   │       ├── MealPlanView.swift
│   │       ├── DayPlanView.swift
│   │       └── RecipePickerView.swift
│   ├── Grocery/
│   │   ├── ViewModels/
│   │   │   └── GroceryViewModel.swift
│   │   └── Views/
│   │       ├── GroceryListView.swift
│   │       ├── GrocerySectionView.swift
│   │       └── GroceryItemRow.swift
│   └── Settings/
│       └── Views/
│           ├── SettingsView.swift
│           ├── ProfileView.swift
│           └── PantryStaplesView.swift
└── Shared/
    └── Components/
        ├── LoadingView.swift
        ├── ErrorView.swift
        └── EmptyStateView.swift
```

## Architecture Patterns

### MVVM Pattern
- **Models**: Codable structs in `Core/Models/`
- **ViewModels**: `@MainActor class` with `ObservableObject` in feature `ViewModels/` folders
- **Views**: SwiftUI views in feature `Views/` folders

### Service Layer
- Singleton services with `static let shared`
- `@MainActor` for main thread safety
- Async/await for all Supabase operations

### Coding Conventions
- All models implement `Codable`, `Identifiable`, `Equatable`
- CodingKeys map snake_case (Supabase) to camelCase (Swift)
- ViewModels use `@Published` for UI state
- Error handling with do/catch blocks

## Features

### Honeydew (Tasks)
- Task list with filters (All, Mine, To Do, Done)
- Create/edit/delete tasks
- Priority levels with color indicators
- Due date tracking

### Recipes
- Searchable recipe library
- Multi-step recipe creation (basics, ingredients, steps)
- Serving adjuster that scales ingredient quantities
- Tags and time estimates

### Meal Plan
- Weekly calendar view with navigation
- Assign recipes to days
- Remove planned meals

### Grocery
- Generate list from meal plan
- Items grouped by category
- Progress tracking
- Manual item addition

### Settings
- User profile view
- Pantry staples management
- Sign out

## Supabase Tables

| Table | Description |
|-------|-------------|
| households | Family households |
| users | User profiles linked to households |
| tasks | Honeydew task items |
| recipes | Recipe library |
| meal_plan | Weekly meal plan entries |
| grocery_lists | Weekly grocery lists |
| grocery_items | Items in grocery lists |
| pantry_staples | Always-have-on-hand items |
| calendar_events | Synced calendar events |
| google_tokens | OAuth tokens for Google Calendar |

## Dependencies

- **Supabase Swift SDK**: Database, auth, realtime

## Build Phases

- [x] Phase 0: Initialization
- [x] Phase 1: Data Models
- [x] Phase 2: Services
- [x] Phase 3: Auth Feature
- [x] Phase 4: App Shell
- [x] Phase 5: Honeydew Feature
- [x] Phase 6: Recipes Feature
- [x] Phase 7: Meal Plan Feature
- [x] Phase 8: Grocery Feature
- [x] Phase 9: Settings Feature
- [x] Phase 10: Shared Components
- [x] Phase 11: Integration & Polish
- [x] Phase 12: Final Verification
