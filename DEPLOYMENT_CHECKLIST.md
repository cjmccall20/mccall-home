# Deployment Checklist — Audit Branch

Everything on `claude/codebase-audit-tiktok-recipes-y6v0b1` that needs a manual
step from you, in order.

## 1. Rotate the leaked password (now)

See `SECURITY_NOTES.md`. Change the Supabase password for
`fmcjmccall12@gmail.com` — it was committed in `Secrets.swift` (now untracked,
but still in git history). Update your local `Secrets.swift` afterward.

## 2. Apply the RLS hardening migration

```bash
cd McCallHome
supabase db push
```

Or paste `supabase/migrations/20260703000000_security_hardening.sql` into the
dashboard SQL editor. Then run the verification queries commented at the bottom
of that file — you should see no `OR true` and no dev-household UUID in any
policy.

Note: the app now calls a new `join_household` RPC for `homerun://join` links,
and RLS blocks direct `users.household_id` updates. **Ship the migration and
the new app build together** — an old app build will get RLS errors on the
join-by-link flow after the migration (invitation-token joins are unaffected).

## 3. Deploy the updated edge functions

```bash
cd McCallHome
supabase functions deploy scrape-recipe
supabase functions deploy generate-grocery-list
supabase functions deploy send-morning-email
supabase functions deploy send-feedback-email
supabase functions deploy send-invitation-email
```

`scrape-recipe` now handles TikTok links (captions via oEmbed — no new API
keys needed). `send-morning-email` was querying columns that don't exist, so
morning emails have never shown meals or tasks; make sure
`household_settings.timezone` is set (e.g. `America/Chicago`) for correct
"today" calculations.

## 4. OAuth configuration

Follow `OAUTH_SETUP.md`: Xcode Sign in with Apple capability check, Supabase
dashboard provider config for Apple (bundle ID) and Google (existing iOS
client ID + skip-nonce-check).

## 5. Build & test in Xcode

The Linux environment can't compile Swift, so give the app one build + smoke
test:

1. Build — if anything fails it will be in the files listed in the commits.
2. Sign up with a **fresh** email → confirm it lands in a brand-new household
   (not your family's data!). This was the cross-tenant bug.
3. Recipes → + → Import from URL → paste a TikTok recipe link (one with the
   recipe written in the caption) → preview → save.
4. Try a TikTok where the recipe is only spoken → confirm the friendly error.
5. Sign out → try both "Sign in with Apple" and Google buttons.
6. Grocery: check/uncheck items rapidly (should feel instant), generate a
   list from the meal plan (should be noticeably faster).
7. Complete a recurring task, uncheck it, re-check it → confirm only one next
   occurrence exists.

## 6. Optional cleanups

- Once you confirm the `profiles` table is empty/unused:
  `DROP TABLE profiles CASCADE;` (the migration locked it in the meantime).
- History purge of the old password (`SECURITY_NOTES.md` §2).
- Edge-function helper tests live in `McCallHome/supabase/functions/tests/`
  and run with `deno test supabase/functions/tests/`.
