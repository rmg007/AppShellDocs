# DATABASE_COMPLETE.md - Complete Database Knowledge

> **CRITICAL**: This is the complete database reference for AI agents.  
> **Last Updated**: 2026-01-31  
> **Source of Truth**: The actual migrations in `supabase/migrations/*.sql`

---

## Quick Reference Card

**File Purpose**: Complete database schema, RLS policies, triggers, and migrations reference.

**When to use this file**:
- Adding/modifying tables or columns
- Setting up RLS policies for new tables
- Understanding JSONB schemas for question types

**Critical sections**: §3 (Table Definitions), §4 (RLS Policies), §5 (RPC Functions)

**Common tasks**:
- Add new table → Section 3 (Table Definitions) + Section 4 (RLS Policies)
- Create RPC function → Section 5 (RPC Functions)
- Check JSONB schema for question type → Section 6 (Field Mapping Reference)
- Write migration → Section 8 (Migration Structure)
- Troubleshoot RLS errors → Section 10 (Validation & Troubleshooting)

**Quick validation**:
```sql
-- Verify helper functions exist and RLS works
SELECT public.is_admin();
SELECT public.is_super_admin();
```

## Table of Contents

1. [Database Overview](#1-database-overview)
2. [Enum Types](#2-enum-types)
3. [Complete Table Definitions](#3-complete-table-definitions)
4. [RLS Policies (Row Level Security)](#4-rls-policies-row-level-security)
5. [RPC Functions](#5-rpc-functions)
6. [Field Mapping Reference](#6-field-mapping-reference)
7. [Business Rules](#7-business-rules)
8. [Migration Structure](#8-migration-structure)
9. [Seed Data](#9-seed-data)
10. [Validation & Troubleshooting](#10-validation--troubleshooting)

---

## 1. Database Overview

### Platform & Philosophy

- **Engine**: PostgreSQL 15+ (Supabase)
- **Security Model**: Row Level Security (RLS) on ALL tables - NO table is public
- **Soft Delete**: EVERY table has `deleted_at` (required for delta sync)
- **Timestamps**: EVERY table has `updated_at` (required for delta sync)
- **Idempotency**: All migrations use `IF NOT EXISTS` or `CREATE OR REPLACE`

### User Roles (Hierarchical)

```
super_admin > admin > student
```

| Role | Permissions |
|------|-------------|
| `admin` | Curriculum CRUD + publish workflow |
| `student` | Student app only (view published content, submit attempts) |

### Auth Model

- **Provider**: Supabase Auth (Email/Password + Google OAuth)
- **Student Auth**: Anonymous auth (device-bound, no login UI)
- **Admin Registration**: Requires invitation code from super_admin
- **Profile Creation**: Auto-created via `handle_new_user()` trigger (default role = `student`)

---

## 2. Enum Types

### user_role

```sql
CREATE TYPE public.user_role AS ENUM ('admin', 'student');
```

**Usage**: `profiles.role`

### content_status

```sql
CREATE TYPE public.content_status AS ENUM ('draft', 'live');
```

**Usage**: `domains.status`, `skills.status`, `questions.status`

### question_type

```sql
CREATE TYPE public.question_type AS ENUM (
  'multiple_choice',  -- Single correct answer from options
  'mcq_multi',        -- Multiple correct answers allowed
  'text_input',       -- Free text entry
  'boolean',          -- True/False
  'reorder_steps'     -- Order items correctly
);
```

**Usage**: `questions.type`

---

## 3. Complete Table Definitions

### 3.1 profiles

**Purpose**: Extends Supabase `auth.users` with app-specific fields

```sql
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  role public.user_role DEFAULT 'student'::public.user_role NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  is_deactivated BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ
);
```

**Key Points**:
- Auto-created via `handle_new_user()` trigger when user registers
- Default role is `student` (must be manually promoted to admin)
- `is_deactivated` allows disabling accounts without deleting

### 3.2 domains

**Purpose**: Top-level subjects (e.g., "Mathematics")

```sql
CREATE TABLE public.domains (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL CHECK (slug ~ '^[a-z0-9_]+$'),
  title TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  status public.content_status DEFAULT 'draft'::public.content_status NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ
);
```

**Key Points**:
- `slug` must be lowercase alphanumeric + underscores
- `sort_order` determines display order
- `status` cascades to all child skills + questions

### 3.3 skills

**Purpose**: Specific topics within a domain (e.g., "Basic Algebra")

```sql
CREATE TABLE public.skills (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  domain_id UUID REFERENCES public.domains(id) ON DELETE CASCADE NOT NULL,
  slug TEXT NOT NULL CHECK (slug ~ '^[a-z0-9_]+$'),
  title TEXT NOT NULL,
  description TEXT,
  difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
  sort_order INTEGER DEFAULT 0 NOT NULL,
  status public.content_status DEFAULT 'draft'::public.content_status NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ,
  UNIQUE(domain_id, slug)
);
```

**Key Points**:
- `slug` unique within parent domain
- `difficulty_level` 1-5 (1 = easiest)
- `status` cascades to all child questions

### 3.4 questions

**Purpose**: Individual practice items

```sql
CREATE TABLE public.questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  skill_id UUID REFERENCES public.skills(id) ON DELETE CASCADE NOT NULL,
  type public.question_type DEFAULT 'multiple_choice'::public.question_type NOT NULL,
  content TEXT NOT NULL,  -- Question prompt (supports Markdown)
  options JSONB DEFAULT '{}'::jsonb NOT NULL,  -- Type-specific options
  solution JSONB NOT NULL,  -- Correct answer
  explanation TEXT,  -- Shown after answering
  points INTEGER DEFAULT 1 NOT NULL,
  status public.content_status DEFAULT 'draft'::public.content_status NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ
);
```

**JSONB Schemas**:

| Type | `options` Example | `solution` Example |
|------|-------------------|-------------------|
| `multiple_choice` | `{"options": [{"id": "a", "text": "Paris"}]}` | `{"correct_option_id": "a"}` |
| `mcq_multi` | `{"options": [{"id": "a", "text": "Red"}]}` | `{"correct_option_ids": ["a", "c"]}` |
| `text_input` | `{"placeholder": "Enter city"}` | `{"exact_match": "Paris", "case_sensitive": false}` |
| `boolean` | `{}` | `{"correct_value": true}` |
| `reorder_steps` | `{"steps": [{"id": "1", "text": "Step 1"}]}` | `{"correct_order": ["2", "1", "3"]}` |

---

## 4. RLS Policies (Row Level Security)

### 4.1 Helper Functions

**CRITICAL**: All policies use these functions, NOT direct role checks

```sql
-- Check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
      AND role = 'admin'
      AND deleted_at IS NULL
      AND is_deactivated = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.2 Content Tables (domains, skills, questions)

**Pattern**: Admin full access, students read published only

```sql
-- Domains
CREATE POLICY "Admins full access to domains" ON public.domains
  FOR ALL 
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Students can read published domains" ON public.domains
  FOR SELECT 
  USING (status = 'live' AND deleted_at IS NULL);

-- Skills (same pattern)
CREATE POLICY "Admins full access to skills" ON public.skills
  FOR ALL 
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Students can read published skills" ON public.skills
  FOR SELECT 
  USING (status = 'live' AND deleted_at IS NULL);

-- Questions (same pattern)
CREATE POLICY "Admins full access to questions" ON public.questions
  FOR ALL 
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Students can read published questions" ON public.questions
  FOR SELECT 
  USING (status = 'live' AND deleted_at IS NULL);
```

---

## 5. RPC Functions

### 5.1 batch_submit_attempts (PRIMARY STUDENT SUBMISSION)

**CRITICAL**: This is the ONLY way students submit attempts

```sql
CREATE OR REPLACE FUNCTION public.batch_submit_attempts(
  attempts_json JSONB
)
RETURNS SETOF public.attempts AS $$
-- See full implementation in migration file
$$;
```

**Usage**:
```typescript
const { data, error } = await supabase.rpc('batch_submit_attempts', {
  attempts_json: [
    {
      id: 'client-generated-uuid',
      question_id: 'question-uuid',
      response: { selected_option_id: 'a' },
      is_correct: true,
      score_awarded: 1,
      time_spent_ms: 3000,
      created_at: '2026-01-29T10:00:00Z'
    }
  ]
});
```

**Key Points**:
- Server ALWAYS assigns `user_id = auth.uid()` (clients cannot spoof)
- Idempotent via `ON CONFLICT (id) DO UPDATE`
- Returns all upserted records
- DO NOT include `user_id` in payload

---

## 6. Field Mapping Reference

### Naming Conventions

| PostgreSQL (snake_case) | Dart (camelCase) | TypeScript (snake_case) |
|------------------------|------------------|------------------------|
| `created_at` | `createdAt` | `created_at` |
| `is_published` | `isPublished` | `is_published` |
| `domain_id` | `domainId` | `domain_id` |
| `sort_order` | `sortOrder` | `sort_order` |

---

**END OF DATABASE_COMPLETE.md**