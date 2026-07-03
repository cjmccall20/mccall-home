# Security Notes — Action Required

## 1. Rotate the dev account password (do this first)

`McCallHome/McCallHome/Secrets.swift` was committed to this repository even though it
was meant to be gitignored (the `.gitignore` entry used the wrong relative path —
now fixed). It contains the real Supabase password for the dev account
`fmcjmccall12@gmail.com`.

The file has been removed from git tracking, **but it still exists in git history**.
Treat that password as compromised:

1. Change the password for `fmcjmccall12@gmail.com` in Supabase
   (Dashboard → Authentication → Users → reset password, or via the app's
   forgot-password flow).
2. If that password is reused anywhere else (email, iCloud, etc.), change it there too.
3. Update your local `Secrets.swift` with the new password. The file stays on disk
   for local builds; it is no longer tracked by git.

## 2. Optional: purge the password from git history

Removing the file from tracking stops future leaks but the old commits still contain
it. If the repo is (or ever becomes) public, scrub history:

```bash
# Using git-filter-repo (recommended; install: pip install git-filter-repo)
git filter-repo --invert-paths --path McCallHome/McCallHome/Secrets.swift

# Then force-push all branches (coordinate with anyone else who has clones)
git push origin --force --all
git push origin --force --tags
```

Since this is a private personal repo, rotating the password (step 1) is the part
that actually matters; history scrubbing is defense in depth.

## 3. Backend hardening shipped in this branch

- New migration `McCallHome/supabase/migrations/20260703000000_security_hardening.sql`
  closes several RLS holes (open invitation policies, dev-household backdoor,
  unrestricted household inserts, self-service household hopping). Apply it with
  `supabase db push` (or paste into the SQL editor) and run the verification
  queries commented at the bottom of the file.
- New signups now always create their own household instead of silently joining
  the first household in the database.
