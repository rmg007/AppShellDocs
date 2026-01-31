# API_CONTRACTS.md - Complete API Reference

> **CRITICAL**: Complete API contracts for AI agents  
> **Last Updated**: 2026-01-31  
> **Read First**: Review AGENT_MASTER.md and SCHEMA.md

---

## Quick Reference Card

**File Purpose**: Complete API reference - REST endpoints, RPC functions, and exact request/response payloads.

**When to use this file**:
- Calling Supabase APIs from frontend
- Understanding request/response formats
- Implementing sync or auth flows

**Critical sections**: §2 (Authentication), §4 (RPC Functions), §6 (Sync API)

**Common tasks**:
- Submit student attempts (ONLY via RPC) → Section 4.1 (batch_submit_attempts)
- Implement admin login flow → Section 2.3 (Admin Login)
- Set up delta sync → Section 6 (Sync API)
- Handle curriculum publishing → Section 4.2 (publish_curriculum)

**Quick validation**:
```typescript
// Test RPC is accessible (run in browser console on logged-in admin)
const { data, error } = await supabase.rpc('batch_submit_attempts', { attempts_json: [] });
console.log(error ? 'Error: ' + error.message : 'RPC accessible');
```

## Table of Contents

1. [API Overview](#1-api-overview)
2. [Authentication](#2-authentication)
3. [REST Endpoints](#3-rest-endpoints)
4. [RPC Functions](#4-rpc-functions)
5. [Realtime Subscriptions](#5-realtime-subscriptions)
6. [Sync API](#6-sync-api)
7. [Error Responses](#7-error-responses)

---

## 1. API Overview

### Base URLs

```
REST API:     https://<project-ref>.supabase.co/rest/v1
Auth API:     https://<project-ref>.supabase.co/auth/v1
Realtime:     wss://<project-ref>.supabase.co/realtime/v1
```

### Required Headers

```http
Authorization: Bearer <access_token>
apikey: <anon_key>
Content-Type: application/json
```

### User Roles

| Role | Access |
|------|--------|
| `admin` | Full curriculum CRUD + publish + read all attempts |
| `student` | Read published content + submit attempts |

**Note**: RBAC uses `profiles.role` only (no separate user_roles table). `is_admin()` function checks `role = 'admin'`.

---

## 2. Authentication

### 2.1 Student Auth (Anonymous)

**Endpoint**: `POST /auth/v1/signup`

**Request** (Anonymous Auth):
```json
{
  "email": null,
  "password": null
}
```

**Response**:
```json
{
  "access_token": "eyJhbGc... (device-bound)",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": {
    "id": "uuid",
    "role": "authenticated"
  }
}
```

**Auto-Created Profile**:
- Database trigger creates `profiles` row with `role = 'student'`
- Device-bound session (no persistent login UI)

**Note**: Students use anonymous auth per PC-006. No email/password required.

### 2.2 Admin Login (Email/Password)

**Endpoint**: `POST /auth/v1/token?grant_type=password`

**Request**:
```json
{
  "email": "admin@example.com",
  "password": "adminpassword"
}
```

**Post-Login Verification**:
```typescript
// Check if user is admin
const { data: profile } = await supabase
  .from('profiles')
  .select('role')
  .eq('id', user.id)
  .single();

if (profile.role !== 'admin') {
  throw new Error('Unauthorized');
}
```

---

## 3. REST Endpoints

### 3.1 Domains

#### List Domains (Student)

**Endpoint**: `GET /rest/v1/domains`

**Query Parameters**:
```
?select=*
&is_published=eq.true
&deleted_at=is.null
&order=sort_order.asc
```

**Response**:
```json
[
  {
    "id": "uuid",
    "slug": "mathematics",
    "title": "Mathematics",
    "description": "Fundamental math concepts",
    "sort_order": 1,
    "is_published": true,
    "created_at": "2026-01-29T10:00:00Z",
    "updated_at": "2026-01-29T10:00:00Z",
    "deleted_at": null
  }
]
```

#### List Domains (Admin)

**Endpoint**: `GET /rest/v1/domains`

**Query Parameters**:
```
?select=*
&order=sort_order.asc
```

**Response**: Same as student, but includes `is_published=false` domains

#### Create Domain (Admin)

**Endpoint**: `POST /rest/v1/domains`

**Request**:
```json
{
  "slug": "physics",
  "title": "Physics",
  "description": "Physical sciences",
  "sort_order": 2,
  "is_published": false
}
```

**Response**:
```json
{
  "id": "new-uuid",
  "slug": "physics",
  "title": "Physics",
  "description": "Physical sciences",
  "sort_order": 2,
  "status": "draft",
  "created_at": "2026-01-29T10:05:00Z",
  "updated_at": "2026-01-29T10:05:00Z",
  "deleted_at": null
}
```

#### Update Domain (Admin)

**Endpoint**: `PATCH /rest/v1/domains?id=eq.<uuid>`

**Request**:
```json
{
  "title": "Updated Title",
  "status": "live"
}
```

**IMPORTANT**: Publishing cascades to children (see BR-004 in DATA_MODEL.md)

#### Delete Domain (Admin) - Soft Delete

**Endpoint**: Use RPC `soft_delete_domain` instead of REST DELETE (future implementation)

**Why**: Ensures proper cascade to children

---

### 3.2 Skills

#### List Skills (Student)

**Endpoint**: `GET /rest/v1/skills`

**Query Parameters**:
```
?select=*
&domain_id=eq.<domain_uuid>
&status=eq.live
&deleted_at=is.null
&order=sort_order.asc
```

#### Create Skill (Admin)

**Endpoint**: `POST /rest/v1/skills`

**Request**:
```json
{
  "domain_id": "domain-uuid",
  "slug": "algebra_basics",
  "title": "Algebra Basics",
  "description": "Introduction to algebra",
  "difficulty_level": 1,
  "sort_order": 1,
  "status": "draft"
}
```

---

### 3.3 Questions

#### List Questions (Student)

**Endpoint**: `GET /rest/v1/questions`

**Query Parameters**:
```
?select=*
&skill_id=eq.<skill_uuid>
&status=eq.live
&deleted_at=is.null
```

#### Create Question - Multiple Choice

**Endpoint**: `POST /rest/v1/questions`

**Request**:
```json
{
  "skill_id": "skill-uuid",
  "type": "multiple_choice",
  "content": "What is 2 + 2?",
  "options": {
    "options": [
      {"id": "a", "text": "3"},
      {"id": "b", "text": "4"},
      {"id": "c", "text": "5"}
    ]
  },
  "solution": {
    "correct_option_id": "b"
  },
  "explanation": "2 + 2 equals 4",
  "points": 1,
  "status": "draft"
}
```

#### Create Question - MCQ Multi

**Request**:
```json
{
  "skill_id": "skill-uuid",
  "type": "mcq_multi",
  "content": "Which of these are prime numbers?",
  "options": {
    "options": [
      {"id": "a", "text": "2"},
      {"id": "b", "text": "4"},
      {"id": "c", "text": "7"},
      {"id": "d", "text": "9"}
    ]
  },
  "solution": {
    "correct_option_ids": ["a", "c"]
  },
  "explanation": "2 and 7 are prime numbers",
  "points": 2,
  "is_published": false
}
```

#### Create Question - Text Input

**Request**:
```json
{
  "skill_id": "skill-uuid",
  "type": "text_input",
  "content": "What is the capital of France?",
  "options": {
    "placeholder": "Enter city name"
  },
  "solution": {
    "exact_match": "Paris",
    "case_sensitive": false
  },
  "explanation": "Paris is the capital of France",
  "points": 2,
  "is_published": false
}
```

#### Create Question - Boolean

**Request**:
```json
{
  "skill_id": "skill-uuid",
  "type": "boolean",
  "content": "Is the sky blue?",
  "options": {},
  "solution": {
    "correct_value": true
  },
  "explanation": "Yes, the sky appears blue",
  "points": 1,
  "is_published": false
}
```

#### Create Question - Reorder Steps

**Request**:
```json
{
  "skill_id": "skill-uuid",
  "type": "reorder_steps",
  "content": "Order the steps to solve a quadratic equation",
  "options": {
    "items": [
      "Identify coefficients a, b, c",
      "Apply quadratic formula",
      "Calculate discriminant",
      "Check if solutions are real"
    ]
  },
  "solution": {
    "correct_order": [
      "Identify coefficients a, b, c",
      "Calculate discriminant",
      "Apply quadratic formula",
      "Check if solutions are real"
    ]
  },
  "explanation": "Follow the standard quadratic formula process",
  "points": 3,
  "is_published": false
}
```

---

### 3.4 Attempts (Admin Analytics ONLY)

**CRITICAL**: Students NEVER use REST for attempts. Use `batch_submit_attempts` RPC.

**Endpoint**: `GET /rest/v1/attempts`

**Query Parameters**:
```
?select=*,questions(content)
&user_id=eq.<student_uuid>
&order=created_at.desc
&limit=100
```

**Response**:
```json
[
  {
    "id": "attempt-uuid",
    "user_id": "student-uuid",
    "question_id": "question-uuid",
    "response": {"selected_option_id": "b"},
    "is_correct": true,
    "score_awarded": 1,
    "time_spent_ms": 3000,
    "created_at": "2026-01-29T10:00:00Z",
    "questions": {
      "content": "What is 2 + 2?"
    }
  }
]
```

---

## 4. RPC Functions

### 4.1 batch_submit_attempts (PRIMARY STUDENT SUBMISSION)

**CRITICAL**: This is the ONLY way students submit attempts (per PC-008)

**Endpoint**: `POST /rest/v1/rpc/batch_submit_attempts`

**Request**:
```json
{
  "attempts_json": [
    {
      "id": "client-generated-uuid-1",
      "question_id": "question-uuid",
      "response": {"selected_option_id": "a"},
      "is_correct": true,
      "score_awarded": 1,
      "time_spent_ms": 3000,
      "created_at": "2026-01-29T10:00:00Z"
    },
    {
      "id": "client-generated-uuid-2",
      "question_id": "question-uuid-2",
      "response": {"text": "Paris"},
      "is_correct": true,
      "score_awarded": 2,
      "time_spent_ms": 5000,
      "created_at": "2026-01-29T10:01:00Z"
    }
  ]
}
```

**IMPORTANT**: DO NOT include `user_id` - server assigns from `auth.uid()`

**Response**: Array of upserted attempts
```json
[
  {
    "id": "client-generated-uuid-1",
    "user_id": "server-assigned-uuid",
    "question_id": "question-uuid",
    "response": {"selected_option_id": "a"},
    "is_correct": true,
    "score_awarded": 1,
    "time_spent_ms": 3000,
    "created_at": "2026-01-29T10:00:00Z",
    "updated_at": "2026-01-29T10:05:00Z",
    "deleted_at": null
  }
]
```

**Key Features**:
- Idempotent via `ON CONFLICT (id) DO UPDATE`
- Server enforces `user_id = auth.uid()`
- Handles offline batches

---

### 4.2 publish_curriculum (Admin Only)

**Endpoint**: `POST /rest/v1/rpc/publish_curriculum`

**Auth**: Admin only (calls `is_admin()`)

**Request**: None

**Response**: Void (success) or error

**Behavior**:
- Validates no orphaned content
- Sets curriculum version +1
- Triggers realtime update

**Example**:
```typescript
const { error } = await supabase.rpc('publish_curriculum');
if (error) {
  console.error('Publish failed:', error.message);
} else {
  console.log('Curriculum published successfully');
}
```

---

## 5. Realtime Subscriptions

### 5.1 Curriculum Updates Channel

**Purpose**: Detect when curriculum changes (trigger client-side cache refresh)

**Implementation**:
```typescript
const channel = supabase
  .channel('curriculum-updates')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'curriculum_meta',
    filter: 'id=eq.singleton'
  }, (payload) => {
    console.log('Curriculum updated, version:', payload.new.version);
    // Invalidate curriculum queries
    queryClient.invalidateQueries({ queryKey: ['domains'] });
    queryClient.invalidateQueries({ queryKey: ['skills'] });
    queryClient.invalidateQueries({ queryKey: ['questions'] });
  })
  .subscribe();
```

### 5.2 Admin Content Changes

**Purpose**: Live updates in admin panel

**Implementation**:
```typescript
// Subscribe to domain changes
supabase
  .channel('admin-domains')
  .on('postgres_changes', {
    event: '*',  // INSERT, UPDATE, DELETE
    schema: 'public',
    table: 'domains'
  }, (payload) => {
    console.log('Domain changed:', payload);
    queryClient.invalidateQueries({ queryKey: ['domains'] });
  })
  .subscribe();
```

---

## 6. Sync API

### 6.1 Pull (Download Changes)

**Strategy**: Delta sync using `updated_at` timestamp

**Student App Pattern**:
```typescript
// Get last sync timestamp
const lastSynced = await db.syncMeta.get('domains').lastSyncedAt;

// Pull delta
const { data: domains } = await supabase
  .from('domains')
  .select('*')
  .gt('updated_at', lastSynced.toISOString())
  .eq('is_published', true)
  .is('deleted_at', null);

// Upsert to local DB
for (const domain of domains) {
  await db.domains.upsert(domain);
}

// Update sync meta
await db.syncMeta.upsert({
  tableName: 'domains',
  lastSyncedAt: new Date(),
});
```

**Tables to Sync** (in order):
1. `domains`
2. `skills`
3. `questions`

### 6.2 Push (Upload Changes)

**Strategy**: Process outbox queue

**Student App Pattern**:
```typescript
// Get pending outbox items
const pending = await db.outbox
  .where('tableName', 'attempts')
  .where('syncedAt', null)
  .orderBy('createdAt')
  .toArray();

if (pending.length === 0) return;

// Batch submit via RPC
const payloads = pending.map(item => JSON.parse(item.payload));
const { data, error } = await supabase.rpc('batch_submit_attempts', {
  attempts_json: payloads
});

if (!error) {
  // Mark as synced
  await db.outbox.bulkUpdate(
    pending.map(item => ({
      ...item,
      syncedAt: new Date()
    })))
  );
}
```

---

## 7. Error Responses

### 7.1 Common HTTP Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| `200` | Success | Query returned data |
| `201` | Created | INSERT succeeded |
| `400` | Bad Request | Invalid JSON or missing required field |
| `401` | Unauthorized | Missing or invalid access token |
| `403` | Forbidden | RLS policy denied |
| `404` | Not Found | Resource doesn't exist |
| `409` | Conflict | Unique constraint violation |
| `500` | Server Error | Database error |

### 7.2 RLS Policy Denied (403)

**Response**:
```json
{
  "code": "42501",
  "message": "new row violates row-level security policy for table \"domains\"",
  "details": null,
  "hint": null
}
```

**Solution**: Check user role in `profiles` table

### 7.3 Unique Constraint Violation (409)

**Response**:
```json
{
  "code": "23505",
  "message": "duplicate key value violates unique constraint \"domains_slug_key\"",
  "details": "Key (slug)=(mathematics) already exists.",
  "hint": null
}
```

**Solution**: Use different slug or update existing

### 7.4 Authentication Required (401)

**Response**:
```json
{
  "message": "JWT expired"
}
```

**Solution**: Refresh session with refresh token

---

## Quick Reference Card

### Student Submissions
```typescript
// ✅ CORRECT
await supabase.rpc('batch_submit_attempts', { attempts_json: [...] });

// ❌ WRONG
await supabase.from('attempts').insert(attempt);
```

### Admin Content Updates
```typescript
// ✅ CORRECT (for publishing)
await supabase.rpc('publish_curriculum');

// ✅ CORRECT (for status change)
await supabase.from('domains').update({ is_published: true }).eq('id', id);
```

### Sync Strategy
```typescript
// Pull changes
const { data } = await supabase
  .from('domains')
  .select('*')
  .gt('updated_at', lastSync)
  .eq('is_published', true)
  .is('deleted_at', null);

// Push attempts
await supabase.rpc('batch_submit_attempts', { attempts_json: batch });
```

---

**END OF API_CONTRACTS.md**