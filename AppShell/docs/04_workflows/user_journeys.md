# User Journey Workflows

## Workflow ID: `WF-001` - Student Question Practice
**Actor:** Student User
**Trigger:** Student selects a skill to practice

### Pre-conditions
1. Student app is installed and has local curriculum data
2. Student has anonymous auth session
3. Selected skill has published questions

### Process Flow (Step-by-Step)
1. **User Action:** Student navigates to skill list and taps "Practice" on a skill.
2. **System Action:** App queries local database for questions in the skill.
    * *If No Questions:* Show "No questions available" message.
    * *If Questions Available:* Load first question.
3. **UI Action:** Display question with options/input field.
4. **User Action:** Student submits answer.
5. **System Action:** Validate answer against solution.
    * *If Correct:* Award points, update streak, show explanation.
    * *If Incorrect:* Show correct answer and explanation, reset streak.
6. **Data Action:** Create attempt record in local database, queue for sync.
7. **System Action:** Update skill_progress aggregates locally.
8. **UI Action:** Show next question or "Session Complete" screen.

### Post-conditions
* Attempt is recorded locally and queued for server sync
* Progress metrics are updated
* Session analytics are tracked

---

## Workflow ID: `WF-002` - Admin Content Publishing
**Actor:** Admin User
**Trigger:** Admin clicks "Publish" on a domain

### Pre-conditions
1. Admin is logged in with admin role
2. Domain exists with skills and questions
3. All content is validated (no orphans)

### Process Flow (Step-by-Step)
1. **User Action:** Admin navigates to domain management and clicks "Publish Domain".
2. **System Action:** Validate domain has skills, skills have questions.
    * *If Validation Fails:* Show error with specific issues.
    * *If Valid:* Proceed to publish.
3. **Data Action:** Call `publish_curriculum` RPC with domain_ids.
4. **System Action:** Update domain.is_published = true, bump curriculum version.
5. **UI Action:** Show success message, trigger real-time updates.
6. **System Action:** Notify connected student apps via realtime subscription.

### Post-conditions
* Domain is visible to students
* Curriculum version is incremented
* Student apps receive update notification

---

## Workflow ID: `WF-003` - Offline Sync
**Actor:** System (background process)
**Trigger:** Network connectivity restored or manual sync

### Pre-conditions
1. Outbox has pending items
2. Network connection available
3. Valid auth session

### Process Flow (Step-by-Step)
1. **System Action:** Process outbox items in FIFO order.
2. **Data Action:** For attempts, call `batch_submit_attempts` RPC.
    * *If RPC Fails:* Retry with exponential backoff.
    * *If Success:* Mark item as synced, remove from outbox.
3. **System Action:** Pull server changes using delta sync (updated_at > last_sync).
4. **Data Action:** Apply server changes to local database, resolve conflicts.
5. **System Action:** Update sync_meta timestamps.
6. **UI Action:** Show sync status indicator.

### Post-conditions
* Local and server data are synchronized
* No data loss occurred
* Sync metadata is updated

---

## Workflow ID: `WF-004` - Admin Question Creation
**Actor:** Admin User
**Trigger:** Admin clicks "Add Question" in skill management

### Pre-conditions
1. Admin is logged in
2. Skill exists and is not published (to allow edits)

### Process Flow (Step-by-Step)
1. **User Action:** Admin fills question form (content, type, options, solution).
2. **System Action:** Validate required fields and solution format.
    * *If Invalid:* Show field-specific errors.
    * *If Valid:* Proceed to save.
3. **Data Action:** Insert question record via REST API.
4. **UI Action:** Show success toast, refresh question list.
5. **System Action:** If skill becomes publishable, enable publish button.

### Post-conditions
* Question is saved and visible in admin interface
* Skill can be published if it has questions

---

## Workflow ID: `WF-005` - Student Authentication
**Actor:** Student User
**Trigger:** First app launch or session expiry

### Pre-conditions
1. App installed on device
2. No existing valid session

### Process Flow (Step-by-Step)
1. **System Action:** Attempt anonymous sign-in with Supabase.
2. **Data Action:** On success, auto-create profile record if needed.
3. **System Action:** Store session tokens locally.
4. **UI Action:** Navigate to main skill selection screen.
    * *If Sign-in Fails:* Show retry option or offline mode.

### Post-conditions
* Student has valid auth session
* Profile exists for progress tracking
* App is ready for use