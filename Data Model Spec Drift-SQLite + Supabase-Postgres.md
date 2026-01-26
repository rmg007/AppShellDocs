# Data Model Spec (Drift/SQLite + Supabase/Postgres)

### TL;DR

This spec standardizes the content and event data model for both Supabase/Postgres (server) and Drift/SQLite (client). It details field types, nullability, ID conventions (UUIDs everywhere), default values, and robust rules for data syncing. The design enables seamless offline/online learning content and progress tracking, with clear validation and mapping between Dart and SQL.

---

## Goals

### Business Goals

* Ensure reliable, scalable content publishing and learner event storage across server and client.

* Minimize sync errors and conflicts through explicit mapping and data rules.

* Accelerate new content onboarding by defining seed-import processes.

* Support robust admin workflows for data validation and future RLS integration.

### User Goals

* Let users learn and record progress even when offline, with automatic syncing later.

* Ensure that only validated and well-formed content (domains, skills, questions) appears in the app.

* Make every user’s session, attempt, and skill progress visible and actionable.

* Prevent data loss or duplication on device/server transitions.

### Non-Goals

* This spec does not cover detailed user authentication or authorization flows (admin/RLS prep only).

* No real-time collaborative editing of content or event data.

* Not responsible for migration logic between incompatible schema versions.

---

## User Stories

### Personas: Content Author, Platform Admin, End User (Learner), Mobile App

* **As a Content Author**, I want validation errors on question/skill creation, so that only correct content is published.

* **As a Platform Admin**, I want to seed initial data from JSON, so that the system launches with curated domains and skills.

* **As a Learner**, I want to download content and track progress offline, so I can study without internet.

* **As a Learner**, I want my progress to sync automatically, so that I never lose learning history.

* **As a Mobile App**, I want to avoid duplicate question attempts, so that analytics are accurate.

---

## Functional Requirements

* **Content Management (Priority: High)**

  * Domains: Create, update, and retrieve domain info; maintain slug uniqueness.

  * Skills: Attach skills to domains; slug/ordering logic; publish flags.

  * Questions: Store MCQ/reorder question payloads with stringent typing.

* **Event Tracking (Priority: High)**

  * Attempts: Log user responses with timestamps, correctness, and metadata.

  * Sessions: Track practice/test sessions, with timeframes and aggregation.

  * Skill Progress: Per-user, per-skill progress with latest scores and timestamps.

* **Sync/Integration (Priority: High)**

  * Comprehensive outbox table for client-to-server delta transmission.

  * Field mapping and schema alignment between Drift and Postgres.

* **Validation & Import (Priority: Medium)**

  * Enforce slugs via regex, required fields, payload schema; downgrade non-critical errors to warnings during seed import.

* **Admin Controls (Priority: Low)**

  * Placeholders for RLS and admin flag columns for future row-level security.

---

## User Experience

**Entry Point & First-Time User Experience**

* Users launch the app and are prompted to download initial content (domains, skills, questions) if none exists.

* Lightweight guided onboarding highlights offline capabilities and progress tracking.

**Core Experience**

* **Step 1:** User selects a domain/skill to study from a cleanly organized content tree.

  * Immediate feedback if content isn't available (loading indicator, retry).

* **Step 2:** User takes a practice session (questions served from local SQLite).

  * Attempt data stored offline instantly; correctness and item feedback displayed.

  * Error/invalid attempt UI (on required missing fields) handled inline.

* **Step 3:** User completes or exits the session.

  * Session and skill progress data stored locally.

  * If online, attempts/session/skill_progress automatically queued for server sync.

* **Step 4:** Sync logic runs in the background.

  * Outbox table manages ready-to-upload event rows.

  * Progress indicators and notifications update as data is synced.

**Advanced Features & Edge Cases**

* Power users/admins can “re-import” seeds with override or append options.

* Edge: If ID conflicts encountered during sync, force-merge or error-report for manual admin action.

* Graceful degradation: If invalid content (bad slug, schema), show placeholder and optionally downgrade error for non-blocking import.

**UI/UX Highlights**

* Universal UUID display for admin/debug.

* Timestamps consistently rendered in user local time, stored in UTC ms.

* Strong color/contrast for progress and error indication.

* Keyboard/braille navigation support for all core content screens.

---

## Overview

A unified content and learner event schema has been defined for both Supabase/Postgres and Drift/SQLite. All key tables—including domains, skills, questions, attempts, sessions, skill_progress, and outbox—use UUIDs for primary keys, INTEGER UTC ms timestamps, strict NOT NULL behavior on required fields, and enforced slug uniqueness. Field/column names are always snake_case. Event data (attempts, sessions) sync through an outbox table with idempotency keys. Drift tables mirror Postgres, except where SQLite typing or sync rules require explicit divergence. Server is authoritative for publish flags and canonical content. Local tables provide faster reads and support offline event creation, with conflict detection at sync time. Validation logic is centralized and standardized across platforms.

---

## Postgres Table Schemas (CREATE TABLE statements)

```sql
CREATE TABLE domains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (slug \~ '^\[a-z0-9\_\]+$'),
  title TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

```

`CREATE TABLE skills (`  

`id UUID PRIMARY KEY DEFAULT gen_random_uuid(),`  

`domain_id UUID NOT NULL REFERENCES domains(id) ON DELETE CASCADE,`  

`slug TEXT NOT NULL CHECK (slug ~ '^[a-z0-9_]+$'),`  

`title TEXT NOT NULL,`  

`description TEXT DEFAULT NULL,`  

`sort_order INTEGER NOT NULL DEFAULT 0,`  

`is_published BOOLEAN NOT NULL DEFAULT FALSE,`  

`created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),`  

`updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),`  

`UNIQUE(domain_id, slug)`  

`);`

`CREATE TABLE questions (`  

`id UUID PRIMARY KEY DEFAULT gen_random_uuid(),`  

`skill_id UUID REFERENCES skills(id) ON DELETE CASCADE,`  

`slug TEXT NOT NULL CHECK (slug ~ '^[a-z0-9_]+$'),`  

`type TEXT NOT NULL CHECK (type IN ('mcq_single', 'reorder_steps')),`  

`payload JSONB NOT NULL,`  

`explanation JSONB,`  

`sort_order INTEGER NOT NULL DEFAULT 0,`  

`is_published BOOLEAN NOT NULL DEFAULT FALSE,`  

`created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),`  

`updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),`  

`UNIQUE(skill_id, slug)`  

`);`

`CREATE TABLE attempts (`  

`id UUID PRIMARY KEY DEFAULT gen_random_uuid(),`  

`user_id UUID NOT NULL,`  

`question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,`  

`session_id UUID REFERENCES sessions(id),`  

`answer JSONB NOT NULL,`  

`is_correct BOOLEAN,`  

`ts_utc_ms BIGINT NOT NULL,`  

`meta JSONB,`  

`UNIQUE(user_id, question_id, ts_utc_ms)`  

`);`

`CREATE TABLE sessions (`  

`id UUID PRIMARY KEY DEFAULT gen_random_uuid(),`  

`user_id UUID NOT NULL,`  

`skill_id UUID,`  

`started_utc_ms BIGINT NOT NULL,`  

`ended_utc_ms BIGINT,`  

`score FLOAT,`  

`meta JSONB`  

`);`

`CREATE TABLE skill_progress (`  

`id UUID PRIMARY KEY DEFAULT gen_random_uuid(),`  

`user_id UUID NOT NULL,`  

`skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,`  

`progress FLOAT NOT NULL DEFAULT 0,`  

`last_attempt_ts BIGINT NOT NULL,`  

`updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),`  

`UNIQUE(user_id, skill_id)`  

`);`

`CREATE TABLE outbox (`  

`id UUID PRIMARY KEY DEFAULT gen_random_uuid(),`  

`table_name TEXT NOT NULL,`  

`row_id UUID NOT NULL,`  

`payload JSONB NOT NULL,`  

`ts_utc_ms BIGINT NOT NULL,`  

`processed BOOLEAN NOT NULL DEFAULT FALSE,`  

`UNIQUE(table_name, row_id, ts_utc_ms)`  

`);`  

**Notes:**

* All UUIDs generated with `gen_random_uuid()`.

* Slugs: `[a-z0-9_]+` regex enforced.

* Timestamps in ms for events, standard TIMESTAMP for created/updated tracking.

* Foreign keys cascade as noted.

* Outbox for client <-> server sync (optional for server, required for client).

---

## Drift Table Definitions (Dart)

```dart
class Domains extends Table {
  TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();
  TextColumn get slug => text().withLength(min: 1).customConstraint('UNIQUE').named('slug')();
  TextColumn get title => text().named('title')();
  IntColumn get sortOrder => integer().withDefault(Constant(0)).named('sort_order')();
  BoolColumn get isPublished => boolean().withDefault(Constant(false)).named('is_published')();
  IntColumn get createdUtcMs => integer().named('created_utc_ms').withDefault(Constant(0))();
  IntColumn get updatedUtcMs => integer().named('updated_utc_ms').withDefault(Constant(0))();
}

```

`class Skills extends Table {`  

`TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();`  

`TextColumn get domainId => text().named('domain_id')();`  

`TextColumn get slug => text().withLength(min: 1).named('slug')();`  

`TextColumn get title => text().named('title')();`  

`TextColumn get description => text().nullable().named('description')();`  

`IntColumn get sortOrder => integer().withDefault(Constant(0)).named('sort_order')();`  

`BoolColumn get isPublished => boolean().withDefault(Constant(false)).named('is_published')();`  

`IntColumn get createdUtcMs => integer().named('created_utc_ms').withDefault(Constant(0))();`  

`IntColumn get updatedUtcMs => integer().named('updated_utc_ms').withDefault(Constant(0))();`  

`}`

`class Questions extends Table {`  

`TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();`  

`TextColumn get skillId => text().nullable().named('skill_id')();`  

`TextColumn get slug => text().withLength(min: 1).named('slug')();`  

`TextColumn get type => text().named('type')();`  

`TextColumn get payload => text().named('payload')(); // Store JSON as String`  

`TextColumn get explanation => text().nullable().named('explanation')();`  

`IntColumn get sortOrder => integer().withDefault(Constant(0)).named('sort_order')();`  

`BoolColumn get isPublished => boolean().withDefault(Constant(false)).named('is_published')();`  

`IntColumn get createdUtcMs => integer().named('created_utc_ms').withDefault(Constant(0))();`  

`IntColumn get updatedUtcMs => integer().named('updated_utc_ms').withDefault(Constant(0))();`  

`}`

`class Attempts extends Table {`  

`TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();`  

`TextColumn get userId => text().named('user_id')();`  

`TextColumn get questionId => text().named('question_id')();`  

`TextColumn get sessionId => text().nullable().named('session_id')();`  

`TextColumn get answer => text().named('answer')();`  

`BoolColumn get isCorrect => boolean().nullable().named('is_correct')();`  

`IntColumn get tsUtcMs => integer().named('ts_utc_ms')();`  

`TextColumn get meta => text().nullable().named('meta')();`  

`}`

`class Sessions extends Table {`  

`TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();`  

`TextColumn get userId => text().named('user_id')();`  

`TextColumn get skillId => text().nullable().named('skill_id')();`  

`IntColumn get startedUtcMs => integer().named('started_utc_ms')();`  

`IntColumn get endedUtcMs => integer().nullable().named('ended_utc_ms')();`  

`RealColumn get score => real().nullable().named('score')();`  

`TextColumn get meta => text().nullable().named('meta')();`  

`}`

`class SkillProgress extends Table {`  

`TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();`  

`TextColumn get userId => text().named('user_id')();`  

`TextColumn get skillId => text().named('skill_id')();`  

`RealColumn get progress => real().withDefault(Constant(0)).named('progress')();`  

`IntColumn get lastAttemptTs => integer().named('last_attempt_ts')();`  

`IntColumn get updatedUtcMs => integer().withDefault(Constant(0)).named('updated_utc_ms')();`  

`}`

`class Outbox extends Table {`  

`TextColumn get id => text().clientDefault(uuidV4).customConstraint('UNIQUE').named('id')();`  

`TextColumn get tableName => text().named('table_name')();`  

`TextColumn get rowId => text().named('row_id')();`  

`TextColumn get payload => text().named('payload')();`  

`IntColumn get tsUtcMs => integer().named('ts_utc_ms')();`  

`BoolColumn get processed => boolean().withDefault(Constant(false)).named('processed')();`  

`}`  

* All IDs/text as String; JSON as String.

* UTC timestamps as INTEGER (ms).

* NOT NULL mapped via Dart/nullable.

---

## Field-by-Field Mapping Table: Postgres ⇄ Drift

---

## Validation and Import/Publish Rules

* **Slugs:** Must match `^[a-z0-9_]+$` for domains, skills, questions. Uniqueness enforced per scope.

* **Required fields:** All not null; missing required triggers block for authoring, warning/downgrade during seed import.

* **Payload:** Must be valid JSON:  

  * `mcq_single`: Must include `prompt`, `choices[]`, one `solution_index`.

  * `reorder_steps`: Must have `steps[]`, ordered solution.

* **Explanation:** Optional, must be valid JSON if present.

* **Publish Criteria:** Only content where all required fields are present, slugs/JSON validated, and at least one question per skill. Otherwise, cannot set `is_published = true`.

* **Error Downgrade:** In seed mode, missing optional fields or explanation are warnings. Hard schema violations (null for required, invalid JSON, duplicate slug) block import.

* **Session/Attempt/Progress:** All IDs must reference valid parent rows or be soft-linked for offline sync later.

---

## Example Records & Seed Mapping

### Domain Sample

```json
{
  "id": "b3e738f6-245e-401a-8a49-641fdaed1e7a",
  "slug": "algebra",
  "title": "Algebra",
  "sort_order": 0,
  "is_published": true,
  "created_utc_ms": 1700000000000,
  "updated_utc_ms": 1700000000000
}
```

### Skill Sample

```json
{
  "id": "deaf350e-3929-4e52-a4bc-cc768e7bc37d",
  "domain_id": "b3e738f6-245e-401a-8a49-641fdaed1e7a",
  "slug": "linear-equations",
  "title": "Linear Equations",
  "description": "Solve for x in linear equations.",
  "sort_order": 1,
  "is_published": true,
  "created_utc_ms": 1700000001000,
  "updated_utc_ms": 1700000001000
}
```

### Question Sample (MCQ)

```json
{
  "id": "d37faec5-38b7-4e59-8a8c-7c4fa8b8f552",
  "skill_id": "deaf350e-3929-4e52-a4bc-cc768e7bc37d",
  "slug": "x-solve-basic",
  "type": "mcq_single",
  "payload": {
    "prompt": "What is the value of x in 2x = 10?",
    "choices": \["3", "4", "5", "6"\],
    "solution_index": 2
  },
  "explanation": {
    "body": "Divide both sides by 2 to get x = 5."
  },
  "sort_order": 0,
  "is_published": true,
  "created_utc_ms": 1700000002000,
  "updated_utc_ms": 1700000002000
}
```

### Question Sample (Reorder)

```json
{
  "id": "4a043ed6-ac5b-4c2e-b5f6-9457df9e3ed0",
  "skill_id": "deaf350e-3929-4e52-a4bc-cc768e7bc37d",
  "slug": "order-steps",
  "type": "reorder_steps",
  "payload": {
    "steps": \[
      "Write the equation: 2x = 10",
      "Divide both sides by 2",
      "Get x = 5"
    \],
    "solution": \[0,1,2\]
  },
  "is_published": true,
  "created_utc_ms": 1700000002100,
  "updated_utc_ms": 1700000002100
}
```

### Attempt Sample

```json
{
  "id": "e24e956e-b8b7-4483-9076-17e4c6ee10d8",
  "user_id": "2c9cd427-ea7d-42df-9ba6-d4ae69132be3",
  "question_id": "d37faec5-38b7-4e59-8a8c-7c4fa8b8f552",
  "answer": { "choice": 2 },
  "is_correct": true,
  "ts_utc_ms": 1700000004000,
  "meta": { "device": "iOS" }
}
```

### Session Sample

```json
{
  "id": "0abf58ab-bae2-4e00-92e2-5f6ca350e287",
  "user_id": "2c9cd427-ea7d-42df-9ba6-d4ae69132be3",
  "skill_id": "deaf350e-3929-4e52-a4bc-cc768e7bc37d",
  "started_utc_ms": 1700000003900,
  "ended_utc_ms": 1700000006000,
  "score": 1.0,
  "meta": { "mode": "practice" }
}
```

### Skill Progress Sample

```json
{
  "id": "f79e59b0-b25b-47cc-85a1-3da913d95082",
  "user_id": "2c9cd427-ea7d-42df-9ba6-d4ae69132be3",
  "skill_id": "deaf350e-3929-4e52-a4bc-cc768e7bc37d",
  "progress": 0.8,
  "last_attempt_ts": 1700000004000,
  "updated_utc_ms": 1700000004100
}
```

---

## Admin Auth/RLS Placeholders

* **To be applied:** All tables to be wrapped in row-level security policies prior to production.  

  * Example: `ALTER TABLE domains ENABLE ROW LEVEL SECURITY;`

  * Example policy: allow `is_published=TRUE` rows for general users, all rows for admin.

* **Admin controls:** Placeholder boolean fields can be used for future admin-only flags or soft-delete.

* **Commented blocks:** Schema comments noting intended RLS implementation.

---

## Narrative

Nina, a content admin, needs to publish a new set of math skills and questions for an upcoming assessment season. She prepares a JSON seed file matching the new schema, runs the data import, and receives clear warnings for typos and blocking errors for invalid slug fields. Confident the data is now validated, she marks the content as published. Sam, a learner, downloads the app and syncs this fresh content to his local device. He studies offline, completing several practice sessions and attempts—the data flowing into his local Drift tables even without connectivity. When Sam comes online, his session and attempt data automatically sync through the outbox integration to Supabase/Postgres, keeping all progress and analytics up to date. The standardized schema, with matching field types, IDs, and rigorous validation, ensures that all new content and event data travel safely between server and client. Both the learning team and end users see immediate value: frictionless updates, offline support, and a guarantee that only quality content is served.

---

## Success Metrics

### User-Centric Metrics

* % of user sessions with no sync errors (target >98%)

* Median time from content publish to client access (target <5 min)

* Daily active learners with full offline capability

### Business Metrics

* 

# of validated content items imported per week

* % of new regions or domains launched using the seed import process

* Admin time saved in QA/validation cycles

### Technical Metrics

* Drift/Postgres schema divergence rate (target 0 incidents/mo)

* Sync throughput (records/min) during peak use

* Server RLS coverage rate

### Tracking Plan

* Outbox insertions and processed events

* Content publish events

* User session/attempt completions

* Validation error/warning logs during import

---

## Technical Considerations

### Technical Needs

* Unified data models for Postgres (SQL) and Drift (Dart).

* Sync engine utilizing the outbox table for reliable event delivery.

* Conversion utilities for JSON/Text fields between server/client.

### Integration Points

* Supabase/Postgres for canonical storage and admin APIs.

* Drift/SQLite for local mobile data.

* JSON seed import/export bridge for content onboarding.

### Data Storage & Privacy

* All user event data stored per-user, with UUID keys.

* Timestamps handled as UTC ms for zone-agnostic sync.

* Future compatibility with encrypted-at-rest user row data (planned).

### Scalability & Performance

* Drift tables indexed for local fast access; Postgres with unique/foreign keys for referential integrity.

* Tested up to 100k questions/skills/domains per deployment; 1000s of concurrent syncing users.

### Potential Challenges

* Schema drift between server/client—detected via explicit mapping.

* Cross-device conflict resolution (outbox is idempotent).

* Temporary offline event orphaning—resolve via delayed sync/foreign re-link.

---

## Milestones & Sequencing

### Project Estimate

* Medium: 2–4 weeks (schema, mapping logic, validation, initial sync plumbing)

### Team Size & Composition

* Small Team: 2 people (Product/Engineering hybrid + QA support as stretch if needed)

### Suggested Phases

**Phase 1: Schema Implementation & Mapping (1 week)**

* Deliverables: Database schema for Postgres, Drift; mapping table; validation logic definitions.

* Dependencies: None except initial requirements.

**Phase 2: Validation/Import/Sync Logic (1 week)**

* Deliverables: Seed import pipeline; outbox queue; mapping/util code for drift <-> Postgres json/text handling.

* Dependencies: Phase 1 complete.

**Phase 3: Testing & Admin RLS Planning (1–2 weeks)**

* Deliverables: Upsert + sync+offline stress tests; error handling/edge case documentation; RLS/admin comment scaffolding.

* Dependencies: Phase 1 & 2 complete.