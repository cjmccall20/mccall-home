# Google Sign-In Setup Guide

This guide walks you through setting up Google Sign-In for calendar integration in McCall Home.

## Prerequisites

- Google Cloud Console account
- Xcode project with bundle ID `com.mccall.home`
- Existing OAuth Client ID: `243332420634-da474f55hp2hn68vkbvfbnjg9r0is1j2.apps.googleusercontent.com`

## Step 1: Add GoogleSignIn SDK

### Using Swift Package Manager

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter the URL: `https://github.com/google/GoogleSignIn-iOS`
3. Select version **7.0.0** or later
4. Add `GoogleSignIn` to your target

### Using CocoaPods (Alternative)

```ruby
pod 'GoogleSignIn', '~> 7.0'
```

## Step 2: Configure URL Scheme

1. Open your project's **Info.plist**
2. Add a URL Scheme with your reversed client ID:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.243332420634-da474f55hp2hn68vkbvfbnjg9r0is1j2</string>
        </array>
    </dict>
</array>
```

## Step 3: Handle URL Callback

Update `McCallHomeApp.swift` to handle the Google Sign-In callback:

```swift
import GoogleSignIn

@main
struct McCallHomeApp: App {
    // ... existing code ...

    var body: some Scene {
        WindowGroup {
            // ... existing view code ...
            .onOpenURL { url in
                // Handle Google Sign-In callback
                GIDSignIn.sharedInstance.handle(url)

                // Handle other deep links (existing code)
                handleDeepLink(url)
            }
        }
    }
}
```

## Step 4: Configure GIDSignIn

Update `GoogleCalendarService.swift` with actual implementation:

```swift
import GoogleSignIn

class GoogleCalendarService: NSObject, ObservableObject {
    // ... existing properties ...

    func signIn() async throws {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw GoogleCalendarError.apiError("No root view controller")
        }

        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config

        // Add calendar scopes
        let additionalScopes = scopes

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: additionalScopes
            )

            // Store tokens
            self.accessToken = result.user.accessToken.tokenString
            self.refreshToken = result.user.refreshToken.tokenString
            self.userEmail = result.user.profile?.email
            self.isSignedIn = true

            // Save refresh token to Supabase
            if let householdId = authService.currentUser?.householdId,
               let refreshToken = self.refreshToken {
                try await settingsService.storeGoogleRefreshToken(
                    for: householdId,
                    refreshToken: refreshToken
                )
            }
        } catch {
            throw GoogleCalendarError.apiError(error.localizedDescription)
        }
    }

    func restorePreviousSignIn() async {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            self.accessToken = user.accessToken.tokenString
            self.refreshToken = user.refreshToken.tokenString
            self.userEmail = user.profile?.email
            self.isSignedIn = true
        } catch {
            // Silent failure - user needs to sign in again
            isSignedIn = false
        }
    }

    func refreshAccessToken() async throws {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleCalendarError.notSignedIn
        }

        try await currentUser.refreshTokensIfNeeded()
        self.accessToken = currentUser.accessToken.tokenString
    }
}
```

## Step 5: Update HouseholdSettingsView

Update the calendar setup flow:

```swift
struct CalendarSetupView: View {
    @ObservedObject var viewModel: HouseholdSettingsViewModel
    @StateObject private var calendarService = GoogleCalendarService.shared

    var body: some View {
        // ... existing UI code ...

        Button {
            Task {
                do {
                    try await calendarService.signIn()
                    // Fetch calendars and let user select one
                    let calendars = try await calendarService.fetchCalendars()
                    // Show calendar picker...
                } catch {
                    viewModel.error = error.localizedDescription
                }
            }
        } label: {
            HStack {
                Image(systemName: "g.circle.fill")
                Text("Sign in with Google")
            }
        }
    }
}
```

## Step 6: Google Cloud Console Configuration

Ensure your OAuth consent screen is configured:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services > OAuth consent screen**
3. Add scopes:
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/calendar.events`
4. Add test users for development

### Enable Calendar API

1. Go to **APIs & Services > Library**
2. Search for "Google Calendar API"
3. Click **Enable**

## Testing

1. Build and run the app
2. Go to **Settings > Household Settings**
3. Toggle "Enable Google Calendar"
4. Complete the Google Sign-In flow
5. Select a calendar to sync with
6. Toggle "Sync meals to calendar"

## Troubleshooting

### "Sign-in failed" Error
- Verify the client ID matches your Google Cloud project
- Check that URL schemes are correctly configured
- Ensure the bundle ID matches `com.mccall.home`

### "Scope not granted" Error
- User may have declined calendar permissions
- Request sign-in again with calendar scopes

### Token Refresh Issues
- Tokens expire after 1 hour
- Use `refreshTokensIfNeeded()` before API calls
- Store refresh token for later use

## Security Notes

- Never commit refresh tokens to source control
- Tokens are stored securely in Supabase with RLS
- Use HTTPS for all API communications
