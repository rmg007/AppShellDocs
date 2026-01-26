# Question & Content Schema Specification (JSON, Validation, Examples)

### TL;DR

This schema provides a standardized, extensible way to define, validate, and store educational questions of multiple types—beginning with single-answer multiple choice (mcq_single) and reorder steps (reorder_steps)—in JSON, with attached hints and explanations. It supports both API payloads and Postgres JSONB storage, enforces robust validation for drafts vs. published status, and enables consistent curriculum mapping/import/export for EdTech engineering and content teams.

---

## Goals

### Business Goals

* Achieve 100% data model consistency for questions across API, database, and internal content tools.

* Reduce engineering onboarding time for curriculum import/export by 50%.

* Enable curriculum teams to publish validated seed data with <1% schema-related publish errors.

* Ensure future extensibility for supporting at least 5 new question types in subsequent phases.

### User Goals

* Allow curriculum authors to create, edit, and export/import high-quality, structured questions with validation feedback.

* Ensure all published content meets minimum standards for hints/explanations and structure.

* Empower downstream API consumers (e.g., web client, reporting) with reliable, predictable data fields.

* Enable content reviewers to identify and resolve schema or validation issues quickly.

### Non-Goals

* Does not provide UI components for rendering questions or authoring tools.

* Does not deliver scoring/analytics logic for student assessment.

* Does not (in Phase 1) support other question types (e.g., open-response, numeric input, code editor).

---

## User Stories

* **Curriculum Author**

  * As a curriculum author, I want to define a new mcq_single question in JSON, so that it validates and is ready for publishing.

  * As a curriculum author, I want to attach structured hints and explanations, so that learners get helpful feedback.

  * As a curriculum author, I want to see clear errors if my question schema is incomplete, so that I can fix issues before publishing.

* **Content Reviewer**

  * As a reviewer, I want to verify that a question’s JSON structure meets publish requirements, so that all live curriculum is high quality.

  * As a reviewer, I want to compare draft and published validation states, so that I understand why content can’t be published.

* **Engineering/DevOps**

  * As an engineer, I want to seed test data into Postgres using JSONB payloads, so that I can quickly bootstrap dev environments.

  * As an engineer, I want a canonical example of import/export mappings, so that integrations and migrations are reliable and automated.

---

## Functional Requirements

* **Question Schema & Types** (Priority: High)

  * Question record envelope supports id, skill_id, sub_skill_id, type, difficulty, status, prompt, payload_json, explanation_json, created/updated timestamps.

  * Support two types: mcq_single and reorder_steps, each with their own payload structure and required fields.

  * Consistent field naming for types and keys.

* **Content Validation** (Priority: High)

  * Authoritative validation for publish/draft with informative errors.

  * Enforce per-type required fields, invariants, and explanation constraints.

* **Hints & Explanations** (Priority: Medium)

  * Uniform, extensible structure for explanation_json supporting title, body, steps\[\] array.

  * Payload must validate for publish; optional for drafts.

* **Seed Data & Mapping** (Priority: Medium)

  * Example curriculum JSON export with domains, skills, and at least 2 questions per type.

  * Canonical mapping reference for import/export to/from API and DB.

---

## User Experience

**Entry Point & First-Time User Experience**

* Users (curriculum authors, engineers) access the schema through in-platform docs, versioned API docs, or sample JSON seed files.

* Sample seeds and validation scripts are provided so first-time adopters can author a question and run validation locally or in a staging environment.

**Core Experience**

* **Step 1:** Author drafts a question record using the envelope, selecting type (mcq_single or reorder_steps).

  * Auto-completion and schema validation assists, with clear required/optional fields.

  * On save, question is assigned a unique, slug-like id (enforced unique across curriculum).

* **Step 2:** Author fills in payload_json per type.

  * For mcq_single, populates choices, correctKey, and prompt text.

  * For reorder_steps, writes steps\[\] array and specifies correctOrder by step ids.

  * UI (or scripts) run real-time validation—drafts may skip explanations but publishing triggers full validation.

* **Step 3:** Attach or author hints/explanations using explanation_json.

  * For publish, must meet all required fields and content quality.

  * Feedback is given if fields are missing (e.g., missing correctKey, steps, duplicate ids).

* **Step 4:** Reviewer checks status, runs publish checks, and advances question to published if all requirements met.

* **Step 5:** Questions can be exported/imported via canonical JSON, mapped 1:1 for use in test fixtures or data seeding.

**Advanced Features & Edge Cases**

* Authoring workflow supports drafts with incomplete fields but surfaces errors on any attempt to publish with missing required content.

* Edge cases (e.g., duplicate step ids, missing correctKey, malformed explanation_json) block publish and trigger downgrade to draft.

* API responds with detailed errors specifying the path and type of schema violation.

**UI/UX Highlights**

* Highly machine-parseable: fixed, snake_case field names and enums for type/status.

* Clear separation of question prompt, payload, and explanation/hints.

* Designed for accessibility: long text fields support markdown, steps/hints as arrays for future i18n.

---

## Narrative

A curriculum author, Maya, is preparing a new math module for a digital learning platform. She needs to create engaging, well-structured questions that both challenge students and provide just-in-time feedback. Using the JSON Question & Content Schema Specification, Maya drafts two types of questions: an mcq_single, where learners choose one correct answer, and a reorder_steps, where learners arrange solution steps in the proper order.

With the schema’s structure and validation tools, Maya attaches clear explanations and concise hints to each question. She receives immediate error feedback if any field is missing or incorrectly formatted, allowing her to correct issues before reviewers see the content. Once all validation rules are satisfied, Maya publishes the curriculum, confident that each question meets both pedagogical and technical standards.

For the platform, this process means that new content is always structurally sound and ready for rapid deployment. Reviewers and engineers alike benefit from reliable import/export and seed-mapping, which reduces manual QA and speeds up iteration across the team. The result: learners get high-quality, interactive practice; curriculum teams save time; and the business scales content with confidence.

---

## Success Metrics

### User-Centric Metrics

* % of questions successfully passing validation on first publish attempt (target: 80%+)

* Rate of schema-related author support tickets (should decrease over time)

* Time to author/import a fully valid curriculum set (target: <2 hours for 10 questions)

### Business Metrics

* Curriculum coverage: # of questions published by type and skill (weekly/monthly)

* Engineering time/cost savings on integration and QA (qualitative/reported)

* Reduction in post-publish schema/structure bugs (target: zero for pilot domains)

### Technical Metrics

* Validation run time per question (target: <50ms/question for batch validation)

* JSONB payload compatibility across environments (0 import/export failures)

* Seed data import/export error rates (<1%)

### Tracking Plan

* Number of draft vs. published questions (per type, per skill/domain)

* Validation error event logs (schema path, error type, user)

* API usage: import/export events, round-trip integrity checks

* Field completeness and usage rate for explanation_json and hints

---

## Technical Considerations

### Technical Needs

* Core validation logic for all question envelope fields and per-type payloads.

* On-the-fly JSON validation endpoints (API), reusable in backend and CLI scripts.

* Data model supports dynamic question schemas (Postgres JSONB for payload_json/explanation_json).

* Test fixtures and migrations seeded with canonical curriculum JSON.

### Integration Points

* Platform back-end (for question persistence/API)

* Internal authoring/review tools (may consume/produce this JSON)

* Staging/production Postgres environments (JSONB fields)

* Downstream clients—web and reporting (read-only consumption)

### Data Storage & Privacy

* All question content (including explanations) stored in JSONB columns.

* Timestamps for created/updated enable content lifecycle tracking.

* No PII or sensitive data—JSON model designed for curriculum, not user data.

* Export/import must comply with internal data usage and audit policies.

### Scalability & Performance

* Should validate and import at least 10,000 question records in under 5 minutes.

* Must handle concurrent authoring/editing and import/export operations seamlessly.

* Schema structured for easy extension to additional types/fields.

### Potential Challenges

* Must defend against accidental schema drift across environments (strict versioning).

* Handling partial/incomplete draft states gracefully without polluting published data.

* Ensuring error logs and messages are actionable for both authors and engineers.

---

## Milestones & Sequencing

### Project Estimate

* Medium: 2–4 weeks (initial schema definition, validation library, examples, and documentation)

### Team Size & Composition

* Small Team: 1–2 people (Product/Content Engineering + Curriculum Specialist/Education)

### Suggested Phases

**Phase 1: Schema Design & Validation Lib (1 week)**

* Key Deliverables: Schema author; define JSON envelope, payload/validation rules, and skeleton test suite.

* Dependencies: Access to representative curriculum and existing API.

**Phase 2: Canonical Sample Data & Export/Import Pipeline (1 week)**

* Key Deliverables: Engineer; provide canonical sample curriculum, seed data scripts, and round-trip import/export tests.

* Dependencies: Postgres instance for JSONB and internal API endpoints.

**Phase 3: Documentation & Internal Rollout (1–2 weeks)**

* Key Deliverables: Team; full spec documentation, sample error logs, training for authors and reviewers.

* Dependencies: Content authoring team engagement, feedback loop.

---

## Overview

This specification defines the data model, validation logic, and canonical examples for structuring all educational questions (Phase 1: mcq_single and reorder_steps) with attached hints/explanations, using JSON for Postgres JSONB storage, curriculum API payloads, and import/export scripts. It describes all supported fields, validation states (draft vs. publish), error handling, and canonical seed data formats to ensure consistent, high-quality curriculum content at scale.

---

## Supported Question Types (Phase 1)

**Type/key naming:**

* All type keys are snake_case, string enums (e.g., "mcq_single", "reorder_steps").

* Field names must be exact and case-sensitive as shown.

---

## JSON Schema: Question Envelope

---

## JSON Schema: MCQ Single (mcq_single)

**payload_json fields:**

**Validation:**

* choices\[\].key must be unique, min 2, max 6 recommended.

* choices\[\].value: non-empty strings.

* correctKey: matches one choices\[\].key.

**explanation_json:**

**Sample Question: Valid mcq_single (ready to publish)**

```json
{
  "id": "add_integers_01",
  "skill_id": "arithmetic_addition",
  "type": "mcq_single",
  "difficulty": "easy",
  "status": "published",
  "prompt": "What is 3 + 4?",
  "payload_json": {
    "choices": \[
      {"key": "A", "value": "6"},
      {"key": "B", "value": "7"}
    \],
    "correctKey": "B"
  },
  "explanation_json": {
    "title": "Adding integers",
    "body": "3 plus 4 equals 7, since 3 + 4 = 7.",
    "steps": \[
      {"title": "Step 1", "body": "Start with 3, add 4 more."}
    \]
  },
  "created_at": "2024-06-14T10:00:00Z",
  "updated_at": "2024-06-14T10:05:00Z"
}
```

**Minimal Draft Example:**

```json
{
  "id": "add_integers_02",
  "skill_id": "arithmetic_addition",
  "type": "mcq_single",
  "difficulty": "easy",
  "status": "draft",
  "prompt": "What is 2 + 5?",
  "payload_json": {
    "choices": \[
      {"key": "A", "value": "6"},
      {"key": "B", "value": "7"}
    \],
    "correctKey": "B"
  },
  "created_at": "2024-06-14T10:10:00Z",
  "updated_at": "2024-06-14T10:10:00Z"
}
```

---

## JSON Schema: Reorder Steps (reorder_steps)

**payload_json fields:**

**Validation:**

* steps\[\].id: unique, non-empty.

* steps\[\].text: non-empty.

* correctOrder: must include all steps\[\].ids, in sequence.

**explanation_json:**

Same as above; must contain at least title and body for publish.

**Sample Question: Valid reorder_steps (published)**

```json
{
  "id": "order_addition_steps_01",
  "skill_id": "arithmetic_addition",
  "type": "reorder_steps",
  "difficulty": "easy",
  "status": "published",
  "prompt": "Arrange the steps to solve 5 + 2 in the correct order.",
  "payload_json": {
    "steps": \[
      {"id": "step_1", "text": "Write the first number: 5"},
      {"id": "step_2", "text": "Add 2 to 5"},
      {"id": "step_3", "text": "Write the answer: 7"}
    \],
    "correctOrder": \["step_1", "step_2", "step_3"\]
  },
  "explanation_json": {
    "title": "Steps to add two numbers",
    "body": "Start by writing the first number, add the second, and record the result.",
    "steps": \[
      {"title": "Step 1", "body": "Write 5."},
      {"title": "Step 2", "body": "Add 2 to 5 to get 7."}
    \]
  },
  "created_at": "2024-06-14T10:20:00Z",
  "updated_at": "2024-06-14T10:25:00Z"
}
```

**Draft Example (incomplete for publish):**

```json
{
  "id": "order_addition_steps_02",
  "skill_id": "arithmetic_addition",
  "type": "reorder_steps",
  "difficulty": "easy",
  "status": "draft",
  "prompt": "Arrange the steps for 2 + 4.",
  "payload_json": {
    "steps": \[
      {"id": "a", "text": "Write 2"},
      {"id": "b", "text": "Add 4 to 2"}
    \],
    "correctOrder": \["a", "b"\]
  },
  "created_at": "2024-06-14T10:30:00Z",
  "updated_at": "2024-06-14T10:30:00Z"
}
```

---

## Hints & Explanation Format

All explanation_json conform to:

* For published questions, both title and body must be non-empty.

* For draft, omitted or partial is allowed (but will block publish).

---

## Validation Rules (Common & Per Type)

**Common:**

* All required envelope fields must be present and non-empty for publish.

* Explanation_json must have non-empty title and body for publish.

* type must match and payload_json must validate for that type.

**mcq_single:**

* Minimum 2 choices; all keys unique/non-empty.

* correctKey matches exactly one choice.

* No duplicate values or empty strings.

* Explanation required for publish.

**reorder_steps:**

* steps\[\].id: unique, non-empty.

* steps\[\].text: non-empty.

* correctOrder: every id in steps, in legal sequence.

* Steps count >= 2.

* Explanation required for publish.

**Draft status:**

* Allows incomplete payloads/explanations.

* On publish attempt, downgrades or blocks with specific error message (field-path, type).

**Edge Cases:**

* Missing/duplicate keys or ids, incorrect correctKey/correctOrder length, empty prompts, malformed JSON.

* API/validation tools log failures with actionable error code and data-path.

---

## Seed Data & Import/Export Mapping

**Canonical curriculum JSON:**

```json
{
  "domains": \[
    {
      "id": "arithmetic",
      "title": "Arithmetic",
      "skills": \[
        {
          "id": "arithmetic_addition",
          "title": "Addition",
          "questions": \[
            // See above for examples: add_integers_01 (mcq_single),
            // order_addition_steps_01 (reorder_steps), etc.
          \]
        }
        // Additional skills...
      \]
    }
    // Additional domains...
  \]
}
```

**Example (abbreviated, 2 per type):**

```json
{
  "domains": \[
    {
      "id": "arithmetic",
      "title": "Arithmetic",
      "skills": \[
        {
          "id": "arithmetic_addition",
          "title": "Addition",
          "questions": \[
            { ...see "add_integers_01" mcq_single above... },
            { ...see "add_integers_02" mcq_single above... },
            { ...see "order_addition_steps_01" reorder_steps above... },
            { ...see "order_addition_steps_02" reorder_steps above... }
          \]
        }
      \]
    }
  \]
}
```

**Import/export mapping:**

* Envelope and payload objects are preserved 1:1 through API and Postgres (JSONB).

* All arrays and enums must maintain field order and exact spelling.

* Schema versioning (if added later) can be a top-level key (not in scope Phase 1).

---

**End of Specification**