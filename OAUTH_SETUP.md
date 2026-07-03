# OAuth Setup — Sign in with Apple + Google

The app code for both providers is complete (native `signInWithIdToken` flow —
no browser redirect, no client secrets in the app). Before the buttons work,
finish these one-time configuration steps.

## 1. Apple — Xcode & Developer Portal

1. Open the project in Xcode → target **McCallHome** → **Signing & Capabilities**.
   The repo already includes `McCallHome.entitlements` with the Sign in with
   Apple entitlement wired into the build settings — Xcode should show the
   capability automatically. If it doesn't, click **+ Capability → Sign in with
   Apple** once so Xcode registers it with your App ID.
2. You need a **paid Apple Developer membership**; automatic signing will add
   the capability to the `com.mccall.McCallHome` App ID in the portal.

## 2. Apple — Supabase Dashboard

Dashboard → **Authentication → Sign In / Up → Apple**:
- Enable the provider.
- In **Client IDs**, add the app's bundle ID: `com.mccall.McCallHome`.
- Leave the OAuth secret fields empty — the native iOS flow doesn't use them.

## 3. Google — Supabase Dashboard

Dashboard → **Authentication → Sign In / Up → Google**:
- Enable the provider.
- In **Authorized Client IDs**, add the iOS client ID already used by the app:
  `243332420634-da474f55hp2hn68vkbvfbnjg9r0is1j2.apps.googleusercontent.com`
- Enable **Skip nonce check** (the GoogleSignIn iOS SDK can't send a custom
  nonce; the app's Apple flow DOES use a proper nonce).
- No client secret needed for the native flow.

## 4. Notes

- **App Review**: because the app offers Google sign-in, Apple requires Sign in
  with Apple to be offered too (it is — both buttons ship together).
- Apple only returns the user's **name on the very first authorization**. The
  app captures it then; if you sign in with Apple on a test account and want a
  do-over, revoke the app under Settings → Apple ID → Sign-In & Security →
  Sign in with Apple, then sign in again.
- Accounts created through OAuth get their **own new household** (same as
  email signup) and can join the family household through an invitation from
  the More tab.
- `McCallHome/supabase/config.toml` contains matching `[auth.external.*]`
  blocks so `supabase start` local development mirrors production.
