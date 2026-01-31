# Database Tables Reference

## Convention
* **Primary Keys:** `id` (UUID)
* **Timestamps:** `created_at`, `updated_at` (UTC), `deleted_at` (Soft delete)
* **Offline-First:** All tables include `updated_at` and `deleted_at` for sync

---

## Table: `profiles`
**Description:** User identity and roles, extends Supabase auth.users

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK**, **FK** → auth.users(id) | User identifier |
| `role` | `user_role` | Not Null, Default: 'student' | User role (admin/student) |
| `email` | `TEXT` | Not Null | User email |
| `full_name` | `TEXT` | Nullable | Display name |
| `avatar_url` | `TEXT` | Nullable | Profile picture URL |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Has Many:** `attempts`, `sessions`, `skill_progress`

---

## Table: `domains`
**Description:** Top-level subject categories (e.g., Mathematics, Physics)

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK** | Domain identifier |
| `slug` | `TEXT` | Unique, Not Null | URL-friendly identifier |
| `title` | `TEXT` | Not Null | Display title |
| `description` | `TEXT` | Nullable | Domain description |
| `sort_order` | `INTEGER` | Not Null, Default: 0 | Display order |
| `is_published` | `BOOLEAN` | Not Null, Default: false | Visibility to students |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Has Many:** `skills`

---

## Table: `skills`
**Description:** Specific topics within domains (e.g., Algebra I)

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK** | Skill identifier |
| `domain_id` | `UUID` | **FK** → domains(id), Not Null | Parent domain |
| `slug` | `TEXT` | Not Null | URL-friendly identifier (unique within domain) |
| `title` | `TEXT` | Not Null | Display title |
| `description` | `TEXT` | Nullable | Skill description |
| `difficulty_level` | `INTEGER` | Check: 1-5, Not Null, Default: 1 | Difficulty rating |
| `sort_order` | `INTEGER` | Not Null, Default: 0 | Display order |
| `is_published` | `BOOLEAN` | Not Null, Default: false | Visibility to students |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Belongs To:** `domains`
* **Has Many:** `questions`, `skill_progress`, `sessions`

---

## Table: `questions`
**Description:** Quiz content with flexible answer structures

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK** | Question identifier |
| `skill_id` | `UUID` | **FK** → skills(id), Not Null | Parent skill |
| `type` | `question_type` | Not Null, Default: 'multiple_choice' | Question type enum |
| `content` | `TEXT` | Not Null | Question text (Markdown) |
| `options` | `JSONB` | Not Null, Default: '{}' | Choice configuration |
| `solution` | `JSONB` | Not Null | Correct answer structure |
| `explanation` | `TEXT` | Nullable | Answer explanation |
| `points` | `INTEGER` | Not Null, Default: 1 | Points awarded |
| `is_published` | `BOOLEAN` | Not Null, Default: false | Visibility to students |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Belongs To:** `skills`
* **Has Many:** `attempts`

---

## Table: `attempts`
**Description:** Student answer submissions (transactional, never deleted)

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK** | Attempt identifier |
| `user_id` | `UUID` | **FK** → profiles(id), Not Null, Default: auth.uid() | Student identifier |
| `question_id` | `UUID` | **FK** → questions(id), Not Null | Question attempted |
| `response` | `JSONB` | Not Null | Student's answer |
| `is_correct` | `BOOLEAN` | Not Null, Default: false | Correctness flag |
| `score_awarded` | `INTEGER` | Not Null, Default: 0 | Points earned |
| `time_spent_ms` | `INTEGER` | Nullable | Time spent in milliseconds |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Submission timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Belongs To:** `profiles`, `questions`

---

## Table: `sessions`
**Description:** Learning session tracking for analytics

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK** | Session identifier |
| `user_id` | `UUID` | **FK** → profiles(id), Not Null, Default: auth.uid() | Student identifier |
| `skill_id` | `UUID` | **FK** → skills(id), Nullable | Skill being practiced |
| `started_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Session start time |
| `ended_at` | `TIMESTAMPTZ` | Nullable | Session end time |
| `questions_attempted` | `INTEGER` | Not Null, Default: 0 | Questions attempted |
| `questions_correct` | `INTEGER` | Not Null, Default: 0 | Correct answers |
| `total_time_ms` | `INTEGER` | Not Null, Default: 0 | Total session time |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Belongs To:** `profiles`, `skills`

---

## Table: `skill_progress`
**Description:** Computed progress aggregates per student per skill

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | **PK** | Progress record identifier |
| `user_id` | `UUID` | **FK** → profiles(id), Not Null, Default: auth.uid() | Student identifier |
| `skill_id` | `UUID` | **FK** → skills(id), Not Null | Skill being tracked |
| `total_attempts` | `INTEGER` | Not Null, Default: 0 | Total attempts |
| `correct_attempts` | `INTEGER` | Not Null, Default: 0 | Correct attempts |
| `total_points` | `INTEGER` | Not Null, Default: 0 | Points accumulated |
| `mastery_level` | `INTEGER` | Check: 0-100, Not Null, Default: 0 | Mastery percentage |
| `current_streak` | `INTEGER` | Not Null, Default: 0 | Current correct streak |
| `best_streak` | `INTEGER` | Not Null, Default: 0 | Best streak achieved |
| `last_attempt_at` | `TIMESTAMPTZ` | Nullable | Last attempt timestamp |
| `created_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | Not Null, Default: NOW() | Last update timestamp |
| `deleted_at` | `TIMESTAMPTZ` | Nullable | Soft delete timestamp |

### Relationships
* **Belongs To:** `profiles`, `skills`

---

## Additional Tables
* `outbox`: Client-side sync queue
* `sync_meta`: Sync metadata per table
* `curriculum_meta`: Curriculum versioning
* See `SCHEMA.md` for complete definitions