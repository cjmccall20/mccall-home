# AUTONOMOUS iOS APP BUILD - McCallHome

## HOW TO USE THIS FILE
Claude Code: Read this file completely, then execute all phases autonomously. Reference back to this file whenever you need to check requirements, patterns, or gates.

---

## YOUR THREE ROLES

You operate as a **self-orchestrating build system** switching between:

1. **[ORCHESTRATOR]** - Manages phases, gates, progress tracking
2. **[BUILDER]** - Writes code, creates files, implements features  
3. **[VERIFIER]** - Tests builds, checks patterns, validates quality

Always prefix your thinking with the current role.

---

## PHASE GATES - MANDATORY

Before moving to any next phase, you MUST pass ALL gate checks.

### GATE PROTOCOL
```
[VERIFIER] Gate Check - Phase X

□ Build succeeds: xcodebuild -scheme McCallHome -sdk iphonesimulator build
□ No compiler errors
□ All new files follow established patterns  
□ ARCHITECTURE.md updated with new files/decisions
□ claude-progress.txt updated with phase completion
□ Git committed with descriptive message
□ Test instructions documented

GATE STATUS: PASS / FAIL
If FAIL: [describe issue and fix before proceeding]
```

---

## PROJECT CONTEXT

**Location:** ~/Desktop/Personal_Projects/mccall-home/McCallHome/

**Existing Files:**
- McCallHomeApp.swift (entry point)
- ContentView.swift (placeholder - will be replaced)
- Config.swift (Supabase URL + anon key configured)
- SupabaseClient.swift (client initialized)
- Supabase SDK already linked in Xcode

**Supabase Tables (already exist in database):**
- households (one row exists: "McCall Family")
- users
- tasks  
- recipes
- meal_plan
- grocery_lists
- grocery_items
- pantry_staples
- calendar_events
- google_tokens

---

## TARGET ARCHITECTURE

```
McCallHome/
├── McCallHomeApp.swift
├── Config.swift
├── SupabaseClient.swift
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

---

## BUILD PHASES

### PHASE 0: INITIALIZATION
**Role:** [ORCHESTRATOR]

Tasks:
- [ ] Read all existing project files to understand current state
- [ ] Create ARCHITECTURE.md documenting the plan
- [ ] Create folder structure (folders only, no empty Swift files)
- [ ] Update claude-progress.txt with session start
- [ ] Git commit: "chore: Initialize project architecture"

**Gate:** ARCHITECTURE.md exists, folder structure created, committed

---

### PHASE 1: DATA MODELS
**Role:** [BUILDER]

Create all Codable structs in Core/Models/ matching Supabase schema exactly.

**Required Pattern:**
```swift
import Foundation

struct HoneydewTask: Codable, Identifiable, Equatable {
    let id: UUID
    let householdId: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var dueTime: String?
    var priority: Priority
    var assignedTo: UUID?
    let createdBy: UUID
    var isComplete: Bool
    var completedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum Priority: String, Codable, CaseIterable {
        case low, medium, high, urgent
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case title
        case description
        case dueDate = "due_date"
        case dueTime = "due_time"
        case priority
        case assignedTo = "assigned_to"
        case createdBy = "created_by"
        case isComplete = "is_complete"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Models to create:**
1. User.swift - id, householdId, name, email, notificationTimes, deviceToken, createdAt
2. Household.swift - id, name, createdAt
3. HoneydewTask.swift - (as shown above)
4. Recipe.swift - id, householdId, title, sourceUrl, sourceType, baseServings, ingredients (as [Ingredient]), steps (as [RecipeStep]), tags, prepTime, cookTime, notes, createdAt, updatedAt
   - Include nested: `struct Ingredient: Codable` and `struct RecipeStep: Codable`
5. MealPlanEntry.swift - id, householdId, recipeId, scheduledDate, servingsOverride, createdAt
6. GroceryList.swift - id, householdId, weekStart, isCurrent, mealPlanHash, generatedAt
7. GroceryItem.swift - id, groceryListId, name, quantity, unit, category, isChecked, sortOrder, createdAt
8. PantryStaple.swift - id, householdId, name, category, createdAt
9. CalendarEvent.swift - id, householdId, googleEventId, title, description, startTime, endTime, allDay, createdBy, syncedAt, createdAt, updatedAt

**Gate:** All models compile with `xcodebuild`, CodingKeys match Supabase snake_case columns

---

### PHASE 2: SERVICES
**Role:** [BUILDER]

Create service classes in Core/Services/ using singleton pattern with async/await.

**Required Pattern:**
```swift
import Foundation
import Supabase

@MainActor
class TaskService: ObservableObject {
    static let shared = TaskService()
    private init() {}
    
    func fetchTasks(for householdId: UUID) async throws -> [HoneydewTask] {
        let response: [HoneydewTask] = try await supabase
            .from("tasks")
            .select()
            .eq("household_id", value: householdId.uuidString)
            .order("due_date", ascending: true)
            .execute()
            .value
        return response
    }
    
    func createTask(_ task: HoneydewTask) async throws {
        try await supabase
            .from("tasks")
            .insert(task)
            .execute()
    }
    
    func updateTask(_ task: HoneydewTask) async throws {
        try await supabase
            .from("tasks")
            .update(task)
            .eq("id", value: task.id.uuidString)
            .execute()
    }
    
    func deleteTask(_ task: HoneydewTask) async throws {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: task.id.uuidString)
            .execute()
    }
}
```

**Services to create:**
1. AuthService.swift
   - signUp(email:password:name:) async throws
   - signIn(email:password:) async throws
   - signOut() async throws
   - @Published var currentUser: User?
   - @Published var isAuthenticated: Bool
   - observeAuthChanges() - listen to Supabase auth state

2. TaskService.swift - CRUD for tasks

3. RecipeService.swift - CRUD for recipes

4. MealPlanService.swift
   - fetchMealPlan(for householdId:, weekStart:) async throws
   - assignRecipe(recipeId:, to date:, householdId:) async throws
   - removeFromPlan(entryId:) async throws

5. GroceryService.swift
   - generateList(from mealPlan:, householdId:) async throws
   - fetchCurrentList(for householdId:) async throws
   - toggleItem(_:) async throws
   - addManualItem(_:) async throws

**Gate:** All services compile, consistent patterns used

---

### PHASE 3: AUTH FEATURE
**Role:** [BUILDER]

Create Features/Auth/ with complete authentication flow.

**AuthViewModel.swift:**
```swift
import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let authService = AuthService.shared
    
    func signIn() async {
        isLoading = true
        error = nil
        do {
            try await authService.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signUp() async {
        isLoading = true
        error = nil
        do {
            try await authService.signUp(email: email, password: password, name: name)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() async {
        try? await authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }
}
```

**Views:**
- AuthContainerView.swift - switches between login/signup
- LoginView.swift - email, password fields, sign in button, link to signup
- SignUpView.swift - name, email, password fields, sign up button, link to login

**Gate:** Auth views render in preview, build succeeds

---

### PHASE 4: APP SHELL
**Role:** [BUILDER]

Update app entry point and create main navigation.

**McCallHomeApp.swift:**
```swift
import SwiftUI
import Supabase

@main
struct McCallHomeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    AuthContainerView()
                        .environmentObject(authViewModel)
                }
            }
            .task {
                await authViewModel.checkSession()
            }
        }
    }
}
```

**MainTabView.swift:**
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HoneydewListView()
                .tabItem {
                    Label("Honeydew", systemImage: "checklist")
                }
            
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            
            MealPlanView()
                .tabItem {
                    Label("Meal Plan", systemImage: "calendar")
                }
            
            GroceryListView()
                .tabItem {
                    Label("Grocery", systemImage: "cart")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
```

Create placeholder views for each tab that just show the tab name.

**Gate:** App builds, runs in simulator, shows auth or tabs based on state

---

### PHASE 5: HONEYDEW FEATURE
**Role:** [BUILDER]

Complete task management feature.

**HoneydewViewModel.swift:**
- @Published var tasks: [HoneydewTask] = []
- @Published var isLoading = false
- @Published var error: String?
- @Published var filter: TaskFilter = .all
- enum TaskFilter { case all, mine, complete, incomplete }
- fetchTasks() async
- createTask(_:) async
- updateTask(_:) async  
- deleteTask(_:) async
- toggleComplete(_:) async
- var filteredTasks: [HoneydewTask] (computed)

**Views:**
- HoneydewListView.swift - List with filter picker, FAB to add, pull to refresh
- HoneydewRowView.swift - Checkbox, title, due date, priority indicator, assignee
- TaskDetailView.swift - Full task details, edit mode, delete button
- CreateTaskView.swift - Form sheet for new task

**Gate:** Build succeeds, task list renders with mock data

---

### PHASE 6: RECIPES FEATURE
**Role:** [BUILDER]

Complete recipe management feature.

**RecipesViewModel.swift:**
- @Published var recipes: [Recipe] = []
- @Published var searchText = ""
- @Published var isLoading = false
- @Published var error: String?
- fetchRecipes() async
- createRecipe(_:) async
- updateRecipe(_:) async
- deleteRecipe(_:) async
- var filteredRecipes: [Recipe] (computed, filter by searchText)

**Views:**
- RecipeListView.swift - Searchable list, FAB to add
- RecipeRowView.swift - Title, prep+cook time, tags preview
- RecipeDetailView.swift - Full recipe with serving adjuster
  - Serving adjuster: stepper that multiplies ingredient quantities
- CreateRecipeView.swift - Multi-step form: basics, ingredients, steps

**Serving Adjuster Logic:**
```swift
func adjustedQuantity(base: Double, baseServings: Int, desiredServings: Int) -> Double {
    return base * (Double(desiredServings) / Double(baseServings))
}
```

**Gate:** Build succeeds, recipe views render

---

### PHASE 7: MEAL PLAN FEATURE
**Role:** [BUILDER]

Weekly meal planning interface.

**MealPlanViewModel.swift:**
- @Published var currentWeekStart: Date
- @Published var entries: [MealPlanEntry] = []
- @Published var recipes: [Recipe] = [] // for picker
- @Published var isLoading = false
- fetchMealPlan() async
- assignRecipe(recipeId:, to date:) async
- removeEntry(_:) async
- goToNextWeek()
- goToPreviousWeek()
- func recipe(for date: Date) -> Recipe?

**Views:**
- MealPlanView.swift - Week header with nav arrows, 7-day grid
- DayPlanView.swift - Single day cell, shows recipe or "Tap to add"
- RecipePickerView.swift - Sheet to select recipe for a day

**Gate:** Build succeeds, week navigation works

---

### PHASE 8: GROCERY FEATURE
**Role:** [BUILDER]

Grocery list generation from meal plan.

**GroceryViewModel.swift:**
- @Published var groceryList: GroceryList?
- @Published var items: [GroceryItem] = []
- @Published var isLoading = false
- fetchCurrentList() async
- generateFromMealPlan() async
- toggleItem(_:) async
- addManualItem(name:, category:) async
- var groupedItems: [String: [GroceryItem]] (grouped by category)

**Category Order:**
1. verify_pantry (Pantry Check)
2. produce
3. dairy
4. meat
5. pantry
6. frozen
7. other

**Views:**
- GroceryListView.swift - Sections by category, generate button, progress indicator
- GrocerySectionView.swift - Collapsible section with items
- GroceryItemRow.swift - Checkbox, name, quantity + unit

**Gate:** Build succeeds, grocery list renders

---

### PHASE 9: SETTINGS FEATURE
**Role:** [BUILDER]

Settings and profile management.

**Views:**
- SettingsView.swift - List with sections: Profile, Household, App
- ProfileView.swift - Edit name, email display (read-only)
- PantryStaplesView.swift - Manage staple items

**Settings Sections:**
- Profile: Name, email
- Household: Household name, members
- Pantry: Manage staple items
- App: Sign out button, version

**Gate:** Build succeeds, settings render

---

### PHASE 10: SHARED COMPONENTS
**Role:** [BUILDER]

Create reusable components.

- LoadingView.swift - Centered ProgressView with optional message
- ErrorView.swift - Error message with retry button
- EmptyStateView.swift - Icon, title, message, optional action button

**Pattern:**
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionTitle: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let action, let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
```

**Gate:** Components compile, used in at least one feature

---

### PHASE 11: INTEGRATION & POLISH
**Role:** [BUILDER] + [VERIFIER]

- [ ] Wire all ViewModels to actual services (replace any mock data)
- [ ] Add loading states to all async operations
- [ ] Add error alerts to all views
- [ ] Add empty states to all lists
- [ ] Add pull-to-refresh where appropriate
- [ ] Ensure all navigation works

**Gate:** Full build succeeds with zero warnings in project code

---

### PHASE 12: FINAL VERIFICATION
**Role:** [VERIFIER]

```
FINAL BUILD VERIFICATION CHECKLIST

1. Clean Build:
   □ xcodebuild clean -scheme McCallHome -sdk iphonesimulator
   □ xcodebuild -scheme McCallHome -sdk iphonesimulator build
   □ Build Succeeded with 0 errors
   □ 0 warnings in McCallHome target (ignore dependency warnings)

2. Architecture Compliance:
   □ All files in correct folders per ARCHITECTURE.md
   □ No files in wrong locations
   □ ARCHITECTURE.md accurately reflects final structure

3. Code Pattern Compliance:
   □ All ViewModels: @MainActor class X: ObservableObject
   □ All Services: @MainActor class X with static shared
   □ All Models: Codable, Identifiable with CodingKeys
   □ All async calls wrapped in do/catch
   □ No force unwraps except UUID literals

4. Documentation:
   □ ARCHITECTURE.md complete
   □ claude-progress.txt has all phases logged
   □ Git log shows incremental commits

5. Manual Test Instructions Created:
   □ How to test auth flow
   □ How to test task creation
   □ How to test recipe creation
   □ How to test meal planning
   □ How to test grocery generation

FINAL STATUS: READY FOR USER TESTING
```

---

## BEST PRACTICES SELF-CHECK

Run after every 3-4 files:

```
[VERIFIER] Pattern Check
□ File in correct folder?
□ Naming convention followed?
□ Code duplicated anywhere? (extract if so)
□ Error handling present?
□ @MainActor where needed?
□ @Published for UI state?
□ Private for internal details?
```

---

## CONTEXT MANAGEMENT PROTOCOL

**If context is getting long (responses slow, losing track):**

1. STOP current work
2. Update claude-progress.txt with detailed state:
   ```
   ## CONTEXT CHECKPOINT - [timestamp]
   Current Phase: X
   Completed: [list files created]
   In Progress: [current file]
   Next Up: [remaining in phase]
   Issues: [any blockers]
   ```
3. Commit all work: `git commit -am "checkpoint: Phase X in progress"`
4. Tell user: "Context checkpoint saved. To continue: 'Resume McCallHome build from [current state]'"

---

## ERROR RECOVERY PROTOCOL

**Build fails:**
1. Read FULL error message
2. Identify root cause file and line
3. Fix the specific issue
4. Rebuild
5. Do not proceed until green

**Stuck in loop (same error 3+ times):**
1. STOP
2. Document what you've tried
3. Ask user for guidance
4. Do NOT keep trying same approach

---

## GIT COMMIT CONVENTIONS

Use conventional commits:
- `feat: Add HoneydewListView with task display`
- `fix: Correct CodingKeys in Recipe model`
- `chore: Update ARCHITECTURE.md with services`
- `refactor: Extract LoadingView component`

Commit after:
- Each model file
- Each service file
- Each complete view
- Each phase completion

---

## PHASE COMPLETION REPORT FORMAT

After each phase:

```
═══════════════════════════════════════════════════════════════
PHASE X COMPLETE: [Phase Name]
═══════════════════════════════════════════════════════════════

Files created:
- Core/Models/HoneydewTask.swift
- Core/Models/Recipe.swift
[etc.]

Build status: ✅ Succeeded

Git commit: abc1234 "feat: Add all data models"

To test: [specific instructions]

Proceeding to Phase [X+1]: [Name]
═══════════════════════════════════════════════════════════════
```

---

## STOP CONDITIONS

Only stop and wait for user if:

1. **Build fails** and you cannot fix after 3 attempts
2. **Need credentials** or config not in existing files
3. **Design decision needed** that significantly impacts UX
4. **Context is full** (checkpoint saved)
5. **All phases complete** (success!)

Otherwise: KEEP GOING.

---

## SUCCESS CRITERIA

Build is complete when:
- [ ] All 12 phases pass their gates
- [ ] App launches in simulator
- [ ] Tab navigation works
- [ ] All features have views (even if Supabase calls need real auth to test)
- [ ] ARCHITECTURE.md matches actual structure
- [ ] Git history shows incremental progress
- [ ] User has clear test instructions

---

## BEGIN

When you receive the start command, execute:

1. [ORCHESTRATOR] Read this entire file
2. [ORCHESTRATOR] Read existing project files
3. [BUILDER] Begin Phase 0
4. Continue through all phases
5. Report completion

Do not stop until all phases complete or a stop condition is met.
