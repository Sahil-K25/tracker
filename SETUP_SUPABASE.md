# Supabase setup — accounts + sync across phone & PC

Follow top to bottom. Do steps 1–5 ONCE. Do step 6 on every device/person.

## 1. Account
- Open: https://supabase.com
- Sign / log in with GitHub

## 2. New project
- Click **New project**
- Name it whatever your folder is (Patron-Rowan2)
- Set a database password (save it somewhere)
- Pick the closest region → **Create**
- Wait ~1 min for it to finish

## 3. Enable accounts (sign up / sign in)
- Left sidebar → **Authentication** → **Providers** → confirm **Email** is enabled (it is by default).
- **Authentication** → **Settings** → "Confirm email":
  - **ON** (default): new accounts must click a link in a confirmation email before they can sign in. Fine for a couple of people, but Supabase's built-in email sender is rate-limited.
  - **OFF**: accounts can sign in immediately after signing up — simplest for a personal/family deploy.
- Optional, once everyone who needs an account has one: turn off **"Allow new users to sign up"** in the same settings page. After that, add any further accounts yourself via **Authentication** → **Users** → **Add user**.

## 4. Run the SQL
- Left sidebar → **SQL Editor** → **New query**
- Paste the contents of `supabase-schema.sql` (in this repo) → click **Run**
- Should say "Success". Re-running it later (e.g. after pulling an update) is safe.

The schema gives every signed-in user their own rows — Postgres Row Level
Security enforces that nobody can read or write anyone else's data, even
though everyone shares the same anon key.

## 5. Get your 2 keys
- Left sidebar → **Project Settings** (gear) → **API**
- Copy **Project URL**  (looks like https://xxxx.supabase.co)
- Copy **anon public** key  (NOT the service_role key)

## 6. Sign in + connect (do on every device)
- Open the app — you'll land on the **Sign in** page.
- First time ever: tap **"Need an account? Sign up"**, enter email + password.
  - If "Confirm email" is ON, check your inbox, click the link, then come back and sign in.
- Once signed in you land on the dashboard. Tap **☁ Cloud sync** (bottom-right) →
  **"Advanced: use your own Supabase project"** → paste **Project URL** + **anon key** →
  **Save & sync**. (Skip this if the deploy already has these baked in as env vars.)
- On every other device, sign in with the **same account** — each account's data is
  private to that account and syncs only between devices signed into it.

## 7. First merge
- Device that HAS your data → ☁ → **⤒ Push this device up**
- Other device → ☁ → **⤓ Pull cloud down**

Done. Finance, water, gym, goals, supplements + progress photos now sync
across every device signed into the same account.

## Already had data before accounts existed?
Nothing is lost. Your existing data is still in this device's `localStorage`.
After you sign up/in on this device, the normal "this device has unpushed
edits → push" sync path creates that account's first cloud snapshot
automatically — no manual migration needed. (Old, ownerless rows from before
accounts existed are no longer reachable under the new policy, but the SQL
above doesn't delete your localStorage data.)

## Sign out
Open **☁ Cloud sync** — if you're signed in, there's a **Sign out** link
under the status line.
