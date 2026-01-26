# Admin Panel Specification (Curriculum Management, Web)

### TL;DR

The web-based admin panel enables education administrators to efficiently create, edit, validate, and publish curriculum content with robust versioning and bulk import/export. All supported question types, domains, and skills can be authored with error-checked workflows. Versioning ensures only validated changes are published, with analytics and audit trails for transparency.

---

## Goals

### Business Goals

* Enable curriculum teams to update and launch new curriculum versions with zero-downtime deployments.

* Decrease curriculum update lead time by 80% by standardizing authoring and validation workflows.

* Reduce manual content errors through validation and versioned publishing.

* Support interoperability with downstream systems via standardized import/export.

### User Goals

* Allow admins to quickly create and edit domains, skills, and questions with real-time validation.

* Provide safe draft-publish workflows with ability to revert or audit changes.

* Enable mass editing/import/export to support complex curriculum launches or migrations.

* Visualize change history and publishing actions for transparency and compliance.

### Non-Goals

* Do not provide student or teacher-facing tools.

* Do not enable deep analytics or custom dashboards beyond basic content change logs.

* No support for multimedia (audio/video) question authoring in MVP.

---

## User Stories

**Persona: Curriculum Admin**

* As a curriculum admin, I want to add new questions of various types so that the curriculum covers recent topics.

* As a curriculum admin, I want to edit domain and skill structures, so I can align them with new educational standards.

* As a curriculum admin, I want to stage changes in draft mode and only publish when ready, to prevent incomplete data release.

* As a curriculum admin, I want to import/export the full curriculum as JSON, so I can perform bulk updates offline.

* As a curriculum admin, I want to see a log of changes and who made them, to ensure accountability within the team.

**Persona: System Maintainer**

* As a system maintainer, I want curriculum updates to sync instantly to student apps upon publish, so students always see the latest content.

* As a system maintainer, I want failed publishes to roll back cleanly so that corrupted states are avoided.

---

## Functional Requirements

* **Curriculum Management (Priority: Critical)**

  * *Domain CRUD:* Create, read, update, and delete curriculum domains.

  * *Skill CRUD:* Manage hierarchical skills within domains.

  * *Question CRUD:* Author/edit/delete questions of all supported types (multiple-choice, short answer, etc.).

  * *Detail/Table Views:* Filter and search by domain, skill, and question type and status.

* **Versioning & Publishing (Priority: Critical)**

  * *Draft/Live Mode Toggle:* Edits are staged as drafts; curriculum must be explicitly published.

  * *Version Promotion:* Publish a full or partial set of edits as a new curriculum version.

  * *Audit Trail:* Log all changes, publishes, and user actions.

* **Content Validation (Priority: High)**

  * *Field Validations:* Enforce required fields, constraints (option counts, valid syntax, etc.).

  * *Error Messaging:* Clear inline errors and summary panels.

  * *Bulk Validation:* Validate imported or batch-edited content.

* **Import/Export (Priority: High)**

  * *JSON Import/Export:* Download/upload entire curriculum or subsets.

  * *Upsert Logic:* Merge on ID or add new records with conflict resolution.

  * *Import Errors:* Non-blocking import; report errors inline and via summary file.

* **Analytics & Logging (Priority: Optional for MVP)**

  * *Basic Usage Analytics:* Track record edits, publishing, and major user actions.

---

## User Experience

**Entry Point & First-Time User Experience**

* Admins log in via a secure (or unprotected for phase 1) URL.

* On first login, a brief “Getting Started” modal or help sidebar describes the main navigation tabs ("Domains," "Skills," "Questions," "Import/Export," "Publish & Audit").

* If curriculum data is empty, a prompt directs the user to create their first domain.

**Core Experience**

* **Step 1:** Navigate Main Panel

  * Left-nav lists primary entities: Domains, Skills, Questions, Import/Export, Publish & Audit.

  * Tab click loads corresponding table view with filters (e.g., domain/skill filter for questions).

  * Successive tabs pre-filtered based on current context (e.g., selecting a domain filters visible skills).

* **Step 2:** Entity Creation/Edit

  * Click "Add" or select row for "Edit." Modal or side-drawer opens with form fields.

  * Fields:

    * *Domain*: Name (text, required), Description (textarea, optional).

    * *Skill*: Name (text, required), Domain (dropdown, required), Parent Skill (dropdown, optional).

    * *Question*:

      * Question Type (dropdown, required)

      * Stem (textarea, required)

      * Solution/Answer (varies by type, required)

      * Options (for multiple-choice, min 2, at least one marked correct)

      * Skill(s) (multiselect, required)

      * Difficulty, Hints, Tags (optional)

  * Real-time validation highlights incomplete/malformed data.

  * “Save” stores the item in Draft state, visible only to admins.

  * “Publish” triggers the publish workflow if all validations pass.

* **Step 3:** Bulk Import/Export

  * Use "Import/Export" tab to download current JSON schema or upload new data.

  * Import runs validations on all records; errors shown in inline table and downloadable error log.

  * Successful records upserted, failed rows ignored unless “block on error” is enabled.

  * Export includes complete nested structure (domains/skills/questions) or filtered subsets.

* **Step 4:** Publish & Audit

  * “Publish” tab displays all draft changes, with summary diff against current production.

  * Click “Promote to Live” to validate and publish updates, versioned and timestamped.

  * View audit history: all edits, publishes, user & timestamp.

  * Rollback button on each publish event: restores previous curriculum version.

* **Step 5:** Question Listing/Filtering

  * Use table/list controls to filter by domain, skill, type, status (draft/published), search by text.

  * Clicking any entry opens detail/edit drawer.

**Advanced Features & Edge Cases**

* Power users can bulk edit or mass-delete with checkbox selection.

* Editable JSON mode for advanced admins to manually tweak raw schema.

* On failed publish (e.g., validation breaks new QA constraint), error modal lists invalid items. No partial publish; changes remain draft to fix and retry.

* If import encounters duplicates, can force overwrite or keep originals (user selectable).

* All destructive actions prompt confirmation with undo snackbar.

* Simultaneous edits: show collision warning and prevent overwrite.

**UI/UX Highlights**

* Responsive layout for large tables and forms.

* Accessible forms: ARIA labels, high-contrast color scheme, proper tab order.

* Sticky save/publish buttons for long edit pages.

* Inline and summary error displays; hovering over errors highlights relevant fields.

* Search, sort, and pagination on all table screens.

* Toast feedback for success/error actions.

---

## Overview & Scope

The admin panel focuses on curriculum entities and authoring with controlled publishing. All core screens:

---

## Content Authoring & Validation Flows

**Adding/Editing Domains, Skills, Questions**

* *Add/Edit Mode*: Modal or side pane. 'Draft’ by default until publish event.

* *Required Field Rules*:

  * Domain: name required

  * Skill: name/domain required; no circular parent

  * Question: all type-specific fields required (e.g., MC options min 2/correct); skill assigned

* *Edit and Draft/Live Modes*:

  * Changes are always drafts; only visible in admin panel until publish.

  * "Save" persists as draft, "Publish" triggers validation, then moves data to published state + increments version.

* *Validation Errors*:

  * Inline red error states near fields, and aggregate error summary.

* *Bulk Import/Export*:

  * Upload/download JSON per schema contract (see below).

  * Only valid records imported; per-record feedback with row index, reason.

**JSON contracts** (Import/Export):  

Sample shape:

{ "domains": \[ {"id": "math1", "name": "Mathematics", "description": ""}, ... \], "skills": \[ {"id": "fraction", "domain_id": "math1", "name": "Fractions", "parent_skill_id": null}, ... \], "questions": \[ { "id": "q001", "type": "multiple_choice", "stem": "What is 1/2 + 1/4?", "skills": \["fraction"\], "options": \[ {"text": "3/4", "is_correct": true}, {"text": "1/4", "is_correct": false} \], "answer": null, "hints": \["Add the numerators", "Common denominator"\], "draft": true } // Repeat for each question type (short_answer, free_response, etc.) \] }

---

## Publish & Versioning Logic

* **Drafts vs Published**:

  * All edits and imported records are drafts by default.

  * “Publish” action validates all changes (new/modified/deleted) and, if no blocking errors, moves them to “Published” and generates a new version number.

* **Per-record vs Version Publishing**:

  * Publishing is per full curriculum version; no partial publishes (all draft changes go live together).

  * Individual record draft edits stay in draft until included in a publish.

* **Workflow for Promoting Curriculum**:

  * Admins review and validate drafts via “Publish” tab.

  * System validates all changes, allowing only valid ones to be promoted.

  * If validation fails, display error with record references; nothing is published.

  * On success, increment version, update publish timestamp, and sync to connected student apps via API webhook or background process.

* **Partial Failures, Reverts, Logging**:

  * No partial publishes—atomic version promotion only.

  * Publish event is logged with user, timestamp, and version.

  * Rollback immediately reverts to previous publish with log entry.

---

## Import/Export & Seed Data

* **JSON Contract**:

  * Same as above; fully nested, domains->skills->questions.

  * ID is canonical; upsert matches records on ID, creates if new, otherwise updates.

* **Upsert Behavior**:

  * Existing IDs updated unless “skip duplicates” flag set.

  * Data not present in import is untouched unless “purge mode” is set.

* **Error Reporting**:

  * Import summary table shows status for each row (success, error, duplicate, validation fail).

  * Downloadable error log (CSV/JSON) with record index, reason.

* **Non-blocking Logic**:

  * Valid rows imported immediately; others flagged.

  * Full error details available inline and via summary export.

* **Sample Import File**:  

  See "JSON contracts" above for schema with all required fields and one sample question per type.

---

## Admin Authentication & Permissions (Placeholder for Phase 2)

* **Supabase Auth Instructions (Phase 2)**:

  * Integrate Supabase Auth, restricted to admin role users.

  * Use authenticated session to set user context for all actions.

  * Add "Sign in" page using basic email/password; hide all content until logged in.

  * Session management with refresh/expiry and “logout.”

* **Row-Level Security (RLS) Policy Outline**:

  * Only admin accounts can write to curriculum tables.

  * Non-admins (future role) may get “read-only” permissions.

* **Phase 1 “Dev Mode” Guidance**:

  * Table access wide-open, but all writes logged to track early usage.

---

## Analytics & Audit Log (Optional for MVP)

* **Tracked Fields**:

  * Record edits: who, when, what changed (field diffs).

  * Status changes: draft → published, published → reverted.

  * Publish/revert events: actor, timestamp, before/after versions.

* **Schema Recommendations**:

  * Either per-entity history fields or append-only audit log table (preferred for scalability).

* **Future Scaling**:

  * Central log with event type, user email, IP, timestamp, entity, entity ID, old/new value blob.

---

## Success Metrics

### User-Centric Metrics

* Time to first curriculum published (minutes/hours).

* Frequency of admin logins and active authoring sessions per week.

* Error rate on saves, publishes, and imports (target: <5% failed attempts).

### Business Metrics

* Number of curriculum releases per month.

* Reduction in manual QA issues post-publish.

* Reduction in curriculum rollout time (comparing pre/post system).

### Technical Metrics

* 99.5% uptime for the admin panel.

* Import/export actions complete in <1 minute for up to 10,000 records.

* Publish latency (time from click to live) <5 seconds.

### Tracking Plan

* User logins

* Entity create/edit/delete

* Publishing events

* Import/export usage

* Validation error events

* Rollback/undo actions

---

## Technical Considerations

### Technical Needs

* REST or GraphQL API for all curriculum entities with validation

* Relational data model (domains, skills, questions, versions, logs)

* Transactional support for versioning and publish workflows

* File upload/download endpoints for import/export

### Integration Points

* Student app consumption endpoint for published curriculum

* Supabase Auth (phase 2) for authentication

* Background publish webhook or polling endpoint for instant sync

### Data Storage & Privacy

* All curriculum data in structured relational tables; published and draft states separated.

* All imports/exports validated and sanitized before persistence.

* User actions logged for all mutating operations.

* Stored audit logs must be tamper-proof and exportable.

### Scalability & Performance

* Designed for up to 20k questions, 500 skills, 100 domains.

* Target response <400ms for table views and edits.

* Batch import/export must handle up to 10k records per operation.

### Potential Challenges

* Handling conflicting simultaneous edits (stale write fails with user warning).

* Ensuring atomic publish (no partial update).

* Change schema migrations if new question types added (future-proof data contracts).

* Secure admin access and correct RLS implementations in phase 2.

---

## Milestones & Sequencing

### Project Estimate

* Medium: 2–4 weeks for MVP

### Team Size & Composition

* Small Team: 2 people (Full-stack developer and Designer/Product hybrid)

### Suggested Phases

**Phase 1: MVP Authoring & Publishing (2 weeks)**

* Key Deliverables:

  * Curriculum entity CRUD (domains, skills, questions) \[Dev\]

  * Draft/publish/versioning flows \[Dev\]

  * Table/list/detail/filter UI \[Design/Front-end\]

  * Validation and error handling \[Dev\]

  * Basic audit log \[Dev\]

  * Import/export (manual only) \[Dev\]

* Dependencies: none (no authentication or external integration)

**Phase 2: Authentication & Fine-Grained Permissions (1 week)**

* Key Deliverables:

  * Supabase Auth integration \[Dev\]

  * RLS policies implemented \[Dev\]

  * Audit log UI improvements \[Design\]

* Dependencies: Completion of Phase 1

**Phase 3: Analytics & Scaling Improvements (1 week, optional)**

* Key Deliverables:

  * Enhanced audit schema \[Dev\]

  * Usage analytics basics \[Dev\]

  * Import/export performance optimization \[Dev\]

* Dependencies: Phases 1 & 2

---