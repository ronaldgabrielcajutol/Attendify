# Attendify

A QR-based attendance app for a school. It's a static site (so it's free to host on GitHub Pages) that talks to a free Supabase database, so every device — the admin's computer, a scanning phone or tablet, and students' own phones — sees the same live data.

Don't want a shared database at all? Leave `config.js` blank (see step 4) and the app runs entirely offline on whichever single device opens it, with no setup required.

## 1. Set up the database (Supabase)

1. Go to [supabase.com](https://supabase.com) and create a free account and a new project.
2. Open your project's **SQL Editor**, paste in the contents of `attendify-setup.sql` (included in this folder), and run it. This creates the tables the app needs and opens them up to the app.
3. Open **Project Settings → API**. You'll need two values from this page in step 4: the **Project URL** and the **anon / publishable key** (not the `service_role`/secret key — never use that one here).

## 2. Put it on GitHub Pages

1. Create a new **public** repository on GitHub (any name).
2. Upload every file in this folder to the root of that repository.
3. In the repo, go to **Settings → Pages**.
4. Under "Build and deployment", set **Source** to "Deploy from a branch", pick the **main** branch and the **/ (root)** folder, then **Save**.
5. After a minute, your site is live at `https://<your-username>.github.io/<repo-name>/`. The admin sign-in page is at that same address with `/admin` on the end.

## 3. Connect the app to your database

Open `config.js` in the repo and fill in the two values from step 1:

```js
var SUPA = { url: "https://abcdefghijkl.supabase.co", key: "your-anon-key-here" };
```

Save and upload that file back to the repo (or edit it directly on GitHub.com). Reload the site — the Settings tab should show "Connected ✓ live database". Sign in with the default admin access key `admin123` and change it immediately under **Settings**.

Leave both values as empty strings (`""`) to skip all of this and run fully offline instead — each device will keep its own local data, and you move data between devices with **Settings → Backup & recovery**.

## Offline use

Even with Supabase connected, the service worker caches the app and its libraries after the first visit, so a device that's briefly offline (or a student scanning in a low-signal spot) keeps working from its local copy and catches up once it's back online.

## A security note

`config.js` — including your Supabase URL and anon key — is visible to anyone who looks at your public GitHub repo or your site's source. That's expected for this kind of app (the anon key is meant to be public; Supabase's security comes from the policies in `attendify-setup.sql`, not from hiding the key), but it does mean anyone who has that URL and key could call the Supabase API directly, bypassing the app's own login screens. If that's a concern:
- Keep the GitHub repo **private** instead of public (GitHub Pages works from a private repo on paid plans, and is free for verified school/education accounts).
- Avoid storing more sensitive student information than you need to.
- Rotate the anon key in Supabase's dashboard if you ever suspect it's leaked beyond your own repo.

## ID cards

Each printable ID card shows a QR code with the student's photo in the middle (to help staff visually confirm it's really that student's card), plus their name, grade and section. Upload student photos under **Students → Add/Edit a student** or **Settings → Set a staff member's photo**. From **Students → Show ID cards**, cards are grouped by section, each with its own "Print this section" button, or print everyone at once with "Print students".
