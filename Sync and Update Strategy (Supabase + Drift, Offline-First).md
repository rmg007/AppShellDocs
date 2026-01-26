# Sync and Update Strategy (Supabase + Drift, Offline-First)

### TL;DR

This strategy establishes a robust sync model between Supabase/Postgres (serving as the authoritative source for all content) and Drift/SQLite (acting as a reliable, always-on cache for instant and offline access). User data—such as progress, attempts, and session details—is stored locally first and synchronized in batches via an outbox queue, supporting resilient offline-first workflows for learners and instructors.

---

## Goals

### Business Goals

* Ensure reliable offline learning functionality with minimal data loss (target: >99.9% sync success across user events).

* Reduce server load by offloading the majority of read operations to local caches (target: 80%+ reads from Drift).

* Improve user satisfaction and retention by offering seamless offline/online handoff (target: increase active user retention by 15%).

* Enable granular audit/logging for all data mutations to support eventual analytics and debugging.

### User Goals

* Instant access to curriculum and personal progress, even without an internet connection.

* No loss of user events or learning progress, regardless of connectivity drops.

* Transparent updates to curriculum and abilities to use latest content without manual refreshes.

* Reliable recovery from device storage issues or mid-session disruptions.

### Non-Goals

* Real-time collaborative editing or multi-user conflict resolution (out of scope).

* Migrating user accounts/authentication between different platforms (not covered).

* UI/UX for out-of-date app versions or manual sync management tools (not in this phase).

---

## User Stories

### Learner

* As a *Learner*, I want to complete questions and track my skill progress offline, so that I can learn anywhere without losing my work.

* As a *Learner*, I want my session and attempt data to sync automatically when internet is available, so that my achievements are up-to-date across devices.

* As a *Learner*, I want to be notified if my curriculum content is obsolete, so that I always study the right material.

### Instructor

* As an *Instructor*, I want to be sure my content updates reach users promptly, so that everyone learns from the latest material.

* As an *Instructor*, I want learners’ progress data to sync reliably to the server, so I can evaluate their performance.

### Support Agent

* As a *Support Agent*, I want clear logs of sync events and error states, so that I can diagnose issues quickly for users.

---

## Functional Requirements

* **Content Sync (Priority: High)**

  * *Curriculum Fetch*: Initial load pulls domains, skills, and questions from Supabase and caches in Drift/SQLite.

  * *Periodic Refresh*: Background jobs refresh cache periodically or on app foreground.

  * *Update Triggers*: Listen for backend change notifications or explicit server signals to force sync.

  * *Delete/Update Handling*: Prune deleted/obsolete content from cache and update changed entities.

* **User Data Sync (Priority: High)**

  * *Local-First Writes*: Writes to attempts, sessions, and progress are persisted locally.

  * *Outbox Queue*: All user data events generate outbox items for later sync with Supabase.

  * *Batch Sync*: Outbox processed on connectivity or retry interval; batch writes use idempotency.

  * *Retry/Dead-letter*: Failed items use exponential backoff; after max retries, flagged for manual review.

* **Conflict & Consistency (Priority: Medium)**

  * *Version Checks*: Skill/question cache tagged with version; flag/warn on use of outdated content.

  * *Last-Write-Wins*: Skill progress updates honor server “greater”/superset values and avoid regressive overwrites.

* **Resilience & Recovery (Priority: Medium)**

  * *Error Handling*: Graceful degradation on corrupt cache, missing content, partial uploads.

  * *Crash Recovery*: On restart, pending outbox items automatically resume processing.

---

## User Experience

**Entry Point & First-Time User Experience**

* Users open the learning app (mobile or offline web).

* If first launch or no content cached, a full curriculum sync is triggered from Supabase, UI shows a “Fetching content…” state.

* Users see a one-time onboarding explaining offline capabilities and transparent sync.

**Core Experience**

* **Step 1:** User selects a module or skill to study.

  * UI instantly displays content using Drift/SQLite cache, zero perceived load.

  * If critical content is missing, fallback prompt to connect to internet or reload.

* **Step 2:** User attempts questions and completes sessions.

  * Each action (question answered, skill progress, session start/end) writes to local tables and creates an outbox record.

  * User sees immediate feedback.

* **Step 3:** Background Process handles outbox.

  * If online, outbox events are pushed in order; on success, records are marked synced and removed.

  * Failures are retried transparently or flagged if persistent.

* **Step 4:** Regular or triggered refreshes update cached content and check version hashes.

  * If server notifies of content update or user foregrounds app, cache is compared and updated for differences.

**Advanced Features & Edge Cases**

* Power-users can view sync status and manually trigger a “force sync.”

* If a device crash occurs, pending outbox is intact and processed on next resume.

* UI clearly distinguishes between “read-only” mode, “out-of-date content,” and “sync pending” states.

**UI/UX Highlights**

* Persistent banners/toasts for content version and sync state.

* Accessibility-first: high contrast, offline error/empty states with actionable suggestions.

* Responsive UI caching and background status updates without jarring transitions.

---

## Narrative

Sophie is a committed learner preparing for her upcoming certification, often studying while commuting, when network access is spotty. She opens the app on the train and, thanks to a recent full curriculum sync, can access all course domains, skills, and questions instantly—even when underground. As she answers questions, her progress and attempts are stored locally, always responsive and never lost to dropped connections.

When she surfaces and her phone reconnects, the app quietly syncs her recent attempts, submitting outbox events in order without disrupting her workflow. Should any connection blip occur, the system retries safely and flags only truly stuck items. When the curriculum updates midweek, Sophie receives a prompt that new material is available; her cache refreshes in the background, ensuring she's always studying up-to-date content.

For her instructor and the support team, Sophie's data is visible server-side, reliably up-to-date, with clear audit logs for any troubleshooting. The process remains invisible unless there's an issue—at which point the app guides her gracefully. Everyone wins: Sophie always makes progress, while the organization gains robust insights and trust in data integrity.

---

## Success Metrics

### User-Centric Metrics

* **Offline Completion Rate:** % of sessions completed offline without perceived data loss.

* **Sync Latency:** Average time between local event creation and successful server sync (<5 minutes).

* **Content Freshness:** % of users with latest curriculum version within 24 hours.

### Business Metrics

* **Active User Retention:** Increase in 30-day retention rate attributable to smooth offline/online experience.

* **Support Ticket Reduction:** % decrease in sync/data loss-related support requests.

* **Infrastructure Efficiency:** Reduction in server-side reads due to effective Drift caching.

### Technical Metrics

* **Sync Success Rate:** % of outbox events eventually successfully synced (>99.9%).

* **Error/Crash Recovery:** Time to recover from crash/partial data loss scenarios (<1 minute).

* **Cache Consistency:** Incidence of cache-server version mismatches.

### Tracking Plan

* Outbox event creation, sync attempt, and completion.

* Cache version check and refresh triggers.

* User actions while offline (attempt, progress, session).

* Error, retry, and dead-letter queue events.

* Background process and server-triggered sync success/failure.

---

## Technical Considerations

### Technical Needs

* **APIs:** REST/RPC endpoints for batch updates and versioned content fetch.

* **Data Models:** Mirror domain, skill, question, session, attempt, and progress tables—plus an outbox table keyed by ULID with required sync metadata.

* **Front-End:** Robust local-DB access layer with Drift/SQLite; background timer/worker for polling and sync.

* **Back-End:** Supabase/Postgres powers authoritative content and event ingestion.

### Integration Points

* Supabase for backend data and webhooks for update notification.

* Drift/SQLite as the persistent always-on UI cache.

* Optional: Push notification or lightweight pub/sub channel for forced content invalidation.

### Data Storage & Privacy

* User data written first to encrypted local tables, then pushed to server.

* Outbox metadata includes minimal PII, obeys GDPR/CCPA best practices.

* Schema-migration-friendly: staged/atomic updates prevent partial/corrupt states.

### Scalability & Performance

* Designed for 10,000+ concurrent users with 1,000,000+ outbox events/day.

* Outbox queue capped (configurable) to avoid runaway local storage.

* Deferred/scheduled sync under background constraints to optimize battery/network impact.

### Potential Challenges

* Ensuring perfect idempotency during retries to prevent duplicate attempts/progress.

* Handling schema/version upgrades without breaking existing cached data.

* Addressing partial uploads or interleaved state across connectivity transitions.

---

## Milestones & Sequencing

### Project Estimate

* **Medium:** 2–4 weeks (major features in 2 weeks, polish/edge-cases in additional 1–2 weeks).

### Team Size & Composition

* **Small Team:** 1–2 people (Product Engineer + QA/Support).

  * Both design and implementation led by product-focused engineer, optionally supported by a part-time QA.

### Suggested Phases

**Phase 1: Core Sync & Outbox (1 week)**

* Key Deliverables: Product Engineer—implement core content fetch, initial local caching, outbox write-and-sync logic.

* Dependencies: Supabase schemas and endpoints stable.

**Phase 2: Conflict Handling & Recovery (1 week)**

* Key Deliverables: Product Engineer—implement version handling, crash recovery, cache-to-server consistency checks.

* Dependencies: Outbox and core logic operational from Phase 1.

**Phase 3: Edge Cases & UI Polish (1 week)**

* Key Deliverables: Product Engineer—error UI states, sync status feedback, “manual sync” and notification hooks.

* Dependencies: Conflict checks and recovery paths in place.

**Phase 4: QA & Stress Test (1 week, parallel/overlap)**

* Key Deliverables: QA/Support—extensive offline/online transition testing, schema migration simulation, edge-case/bulk-data validation.

* Dependencies: All major features functional; can overlap by week with prior phases.

---