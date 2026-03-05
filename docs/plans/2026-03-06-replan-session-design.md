# Replan Session Design

## Problem

Users who complete onboarding but don't have a training plan (e.g. voice session ended before `generate_training_plan` was called) have no way to generate one short of re-running onboarding. Additionally, users need a way to regenerate their plan at any time as their goals change.

## Solution

Add a `replan` session type with a dedicated system prompt that assumes the coach already knows the user. Surface this in two places:

1. **Profile screen** — "Regenerate Plan" button in the Coach section
2. **Plan screen** — Banner shown when no active plan exists, with a "Create Training Plan" button

## Backend Changes

### New session type: `replan`

Add `REPLAN_PROMPT` to `voice/system_prompts/general.py` and register it in `SESSION_TYPE_PROMPTS`.

Prompt behavior:
- Coach opens knowing the user exists and has profile data
- Fetches current profile via `update_user_profile` / context
- Asks only what changed (goal, benchmark time, preferred days)
- Calls `generate_training_plan` once it has enough info
- Confirms the new plan and first workout

Greeting trigger: "The runner wants to update or create their training plan. Check what you know about them and ask what they'd like to change."

## iOS Changes

### Profile screen
Add a second button to the `coachSection`: "Regenerate Plan" — starts a `replan` voice session using `CoachChatSheet` (or a minimal variant that passes `session_type: .replan`).

`VoiceSessionService.SessionType` needs a `replan` case added.

### Plan screen
When `vm.plan == nil` after loading (and `!vm.isLoading`), show a banner:
> "No training plan yet. Talk to your coach to create one."
with a "Create Plan" button that presents the replan sheet.

## Data Flow

```
User taps "Regenerate Plan"
  → iOS opens CoachChatSheet with session type = replan
  → POST /api/voice/session { session_type: "replan" }
  → Backend starts pipeline with REPLAN_PROMPT
  → Coach fetches user profile, asks what changed
  → Coach calls generate_training_plan tool
  → PlanView refreshes on next appear
```

## What Does Not Change

- Onboarding flow is untouched
- `generate_training_plan` tool handler is untouched
- General session type is untouched
