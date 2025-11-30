# McCall Home - Claude Code Development Prompt

## CRITICAL: Read Before Each Session

This is a multi-session iOS app project. Follow these rules:

### Session Start Protocol
1. Run: `pwd` → Confirm you're in mccall-home directory
2. Run: `cat claude-progress.txt` → Read previous session notes
3. Run: `cat feature_list.json | jq '.features[] | select(.passes == false) | .id + ": " + .description' | head -5` → See next features to implement
4. Run: `./init.sh` → Initialize development environment
5. If Xcode project exists: Open and verify it builds

### Session Work Rules
- Work on **ONE feature** at a time from feature_list.json
- Test the feature thoroughly before marking complete
- Commit after each completed feature with descriptive message
- Update claude-progress.txt with what you did

### Session End Protocol
1. Ensure code compiles without errors
2. Commit all changes: `git add . && git commit -m "feat: [description]"`
3. Update feature_list.json - mark completed features as `passes: true`
4. Update claude-progress.txt with:
   - What was completed
   - Any issues encountered
   - What next session should do

---

## Project Context

**App**: McCall Home - Household management for Cooper & wife
**Bundle ID**: com.mccall.home
**Platform**: iOS 17+, SwiftUI, SwiftData for offline

### Core Features
1. **Honeydew (Tasks)**: Create, assign, complete tasks with notifications
2. **Recipes**: Add manually or import from URLs
3. **Meal Plan**: Weekly dinner planning
4. **Grocery List**: Auto-generated from meal plan

### Tech Stack
- iOS: SwiftUI, SwiftData
- Backend: Supabase (PostgreSQL, Auth, Edge Functions)
- Recipe Scraping: Firecrawl API
- Push Notifications: APNs

---

## MCP Available

Supabase MCP is configured. You can:
- "List tables in my Supabase database"
- "Apply this SQL migration"
- "Show data in the tasks table"
- "Generate TypeScript types from schema"

---

## Project Structure

```
mccall-home/
├── ios/McCallHome/
│   ├── App/
│   │   ├── McCallHomeApp.swift      # Entry point
│   │   └── ContentView.swift        # Main tab view
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   ├── SignupView.swift
│   │   │   └── AuthViewModel.swift
│   │   ├── Honeydew/
│   │   │   ├── TaskListView.swift
│   │   │   ├── TaskDetailView.swift
│   │   │   ├── TaskHistoryView.swift
│   │   │   └── HoneydewViewModel.swift
│   │   ├── Recipes/
│   │   │   ├── RecipeListView.swift
│   │   │   ├── RecipeDetailView.swift
│   │   │   ├── AddRecipeView.swift
│   │   │   └── RecipesViewModel.swift
│   │   ├── MealPlan/
│   │   │   ├── MealPlanView.swift
│   │   │   ├── SelectRecipeSheet.swift
│   │   │   └── MealPlanViewModel.swift
│   │   ├── GroceryList/
│   │   │   ├── GroceryListView.swift
│   │   │   └── GroceryViewModel.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── NotificationSettingsView.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   ├── Task.swift
│   │   │   ├── Recipe.swift
│   │   │   ├── MealPlan.swift
│   │   │   └── GroceryItem.swift
│   │   ├── Services/
│   │   │   ├── SupabaseClient.swift
│   │   │   ├── AuthService.swift
│   │   │   ├── NotificationService.swift
│   │   │   └── RecipeScraperService.swift
│   │   └── Persistence/
│   │       └── LocalDataManager.swift
│   └── Resources/
│       └── Assets.xcassets
├── supabase/
│   ├── migrations/
│   │   └── 20240101000000_initial_schema.sql
│   └── functions/
│       ├── scrape-recipe/
│       ├── parse-recipe-text/
│       └── generate-grocery-list/
├── init.sh
├── feature_list.json
├── claude-progress.txt
├── .env.example
└── .gitignore
```

---

## Implementation Order

### Phase 1: Foundation (Sessions 1-3)
1. ✅ Create project files (init.sh, feature_list.json, etc.)
2. Create Xcode project with SwiftUI
3. Add Supabase Swift SDK
4. Apply database migration
5. Implement basic auth (signup, login, session)

### Phase 2: Honeydew Tasks (Sessions 4-6)
6. Task list view with CRUD
7. Task assignment and priority
8. Task completion with notifications
9. Task history view

### Phase 3: Recipes (Sessions 7-10)
10. Manual recipe entry
11. Recipe detail view with serving adjuster
12. URL scraping with Firecrawl
13. Text parsing fallback

### Phase 4: Meal Planning (Sessions 11-12)
14. Weekly calendar view
15. Recipe assignment to days
16. Saturday reminder notification

### Phase 5: Grocery List (Sessions 13-14)
17. List generation from meal plan
18. Category sections
19. Checkboxes with persistence

### Phase 6: Offline & Polish (Sessions 15+)
20. SwiftData sync
21. iPad layout
22. UI polish and testing

---

## Key Code Patterns

### Supabase Client Setup
```swift
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]!)!,
            supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]!
        )
    }
}
```

### Retry with Exponential Backoff
```swift
func withRetry<T>(maxAttempts: Int = 3, operation: () async throws -> T) async throws -> T {
    var delay: UInt64 = 1_000_000_000 // 1 second
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            if attempt == maxAttempts { throw error }
            try await Task.sleep(nanoseconds: delay)
            delay *= 2
        }
    }
    fatalError("Unreachable")
}
```

### SwiftData Model Example
```swift
import SwiftData

@Model
final class LocalTask {
    var id: UUID
    var title: String
    var isComplete: Bool
    var syncStatus: SyncStatus
    var lastModified: Date
    
    enum SyncStatus: String, Codable {
        case synced, pendingUpload, pendingDelete
    }
}
```

---

## Environment Variables

Load from .env file or Xcode scheme environment:
- SUPABASE_URL
- SUPABASE_ANON_KEY
- FIRECRAWL_API_KEY
- ANTHROPIC_API_KEY

---

## Testing Checklist

Before marking a feature complete:
- [ ] Feature works in Simulator
- [ ] No compiler warnings related to feature
- [ ] Handles error states (no internet, bad data)
- [ ] UI looks correct in light and dark mode
- [ ] Data persists after app restart

---

## Remember

- **One feature at a time**
- **Test before marking complete**
- **Commit after each feature**
- **Update progress file**
- **Leave code in buildable state**
