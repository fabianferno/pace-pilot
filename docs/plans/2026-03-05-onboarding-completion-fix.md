# Onboarding Completion Fix

## Problem
After completing the voice onboarding, the app stays stuck on `OnboardingView` with no navigation to `MainTabView`.

Two bugs:
1. `generate_training_plan` never sets `onboarding_complete = true` on the user document
2. iOS never re-fetches the user profile after ending the onboarding session, so `AppRouter` sees stale `onboardingComplete: false`

## Fix

**Backend (`voice/tools/plan_tools.py`):**
After generating workouts, update the user doc with `onboarding_complete: true`.

**iOS (`Features/Onboarding/OnboardingView.swift`):**
After `voice.endSession()`, call `AuthManager.shared.validateSession()` which re-fetches `/api/users/me`. AppRouter observes the updated user and navigates to `.main`.
