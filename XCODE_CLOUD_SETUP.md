# Xcode Cloud → TestFlight setup

The repo side is done: `DesignerBuddy.xcodeproj/xcshareddata/xcschemes/DesignerBuddy.xcscheme`
is a shared scheme (Release archive config), which Xcode Cloud requires. The
remaining steps need your Apple ID and happen in Xcode and App Store Connect —
about 10 minutes, one time.

## Prerequisites

- Apple Developer Program membership on team `W5467D7VFN`
- An app record in App Store Connect for bundle ID `com.wujdesign.buildbuddy`
  (App Store Connect → Apps → **+** → New App, if one doesn't exist yet)

## 1. Create the workflow in Xcode

1. Open `DesignerBuddy.xcodeproj` in Xcode, sign in to your Apple ID
   (Settings → Accounts) if you haven't.
2. **Product → Xcode Cloud → Create Workflow…**
3. Select the **DesignerBuddy** product, click **Next**.
4. Xcode shows a default workflow. Click **Edit Workflow…** and set:
   - **Environment**: latest released Xcode (default is fine).
   - **Start Conditions**: Branch Changes → `main`. Leave "Files and
     Folders" as Any — or restrict to `DesignerBuddy/` +
     `DesignerBuddy.xcodeproj/` so README-only pushes don't burn compute
     hours.
   - **Actions**: one **Archive** action, platform iOS, scheme
     **DesignerBuddy**, deployment preparation **TestFlight (Internal
     Testing Only)**.
   - **Post-Actions**: **TestFlight Internal Testing** → pick (or create)
     an internal tester group.
5. Click **Save**, then **Next**.

## 2. Grant repo access

Xcode will prompt you to connect the GitHub repository:

1. It opens a GitHub page to install the **Xcode Cloud** GitHub app.
2. Install it on the `sleep-drifter` account and grant access to
   **brand-buddy** (repo-only access is enough; no need for all repos).
3. Back in Xcode, complete the flow. Xcode Cloud links the repo and starts
   the first build.

## 3. TestFlight testers

In App Store Connect → your app → TestFlight:

- Add yourself (and anyone else) to the internal group you selected in the
  workflow. Internal testers get every build automatically with no Beta App
  Review.

## How builds work after this

- Every push to `main` triggers an archive and TestFlight upload.
- Xcode Cloud **manages the build number automatically** (`CI_BUILD_NUMBER`)
  — you never need to bump `CURRENT_PROJECT_VERSION` by hand. Bump
  `MARKETING_VERSION` (the user-facing 1.0 / 1.1) in the project when you
  want a new version string.
- Code signing is fully managed by Xcode Cloud; the project's automatic
  signing setup is used as-is. No certificates or profiles to export.
- Monitor builds in Xcode's Report navigator (⌘9 → Cloud tab) or in
  App Store Connect → your app → Xcode Cloud.

## Notes

- No `ci_scripts/` are needed: the project has no package-manager
  dependencies or codegen. If that changes (e.g. you add a step that needs
  tools installed), add a `ci_scripts/ci_post_clone.sh` at the repo root.
- Free tier is 25 compute hours/month, plenty for this project. Usage is
  visible in App Store Connect → Xcode Cloud → Settings.
- To ship a build on demand instead of on every push, change the start
  condition to **Tag Changes** (e.g. tags matching `v*`) and push a tag
  when you want a TestFlight build.
