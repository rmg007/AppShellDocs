# STUDENT_APP_COMPLETE.md - Complete Flutter Student App Guide

> **CRITICAL**: Complete reference for building the Flutter student app  
> **Last Updated**: 2026-01-31  
> **Read First**: Review AGENT_MASTER.md before implementing

---

## Quick Reference Card

**File Purpose**: Complete Flutter implementation guide - database, widgets, sync, and offline-first patterns.

**When to use this file**:
- Building Flutter UI components or screens
- Implementing sync/offline functionality
- Adding new question type widgets

**Critical sections**: §3 (Database Setup), §5 (Feature Implementation), §6 (Sync Engine)

**Common tasks**:
- Set up Drift database correctly → Section 3 (Database Setup - CRITICAL)
- Create new question widget → Section 5.2 (Question Widget Implementations)
- Implement sync push/pull → Section 6 (Sync Engine)
- Add Riverpod provider → Section 4.1 (Riverpod Provider Pattern)
- Handle offline errors → Section 7 (Error Handling)

**Quick validation**:
```bash
# Generate Drift code and verify no errors
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

## Table of Contents

1. [Tech Stack](#1-tech-stack)
2. [Project Structure](#2-project-structure)
3. [Database Setup (Critical)](#3-database-setup-critical)
4. [Core Patterns](#4-core-patterns)
5. [Feature Implementation](#5-feature-implementation)
6. [Sync Engine](#6-sync-engine)
7. [Error Handling](#7-error-handling)
8. [Testing](#8-testing)

---

## 1. Tech Stack

### Dependencies (LOCKED - DO NOT CHANGE)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management (ONLY Riverpod)
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Local Database (Offline-First)
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.0

  # Backend
  supabase_flutter: ^2.0.0

  # Auth
  google_sign_in: ^6.2.0
  flutter_secure_storage: ^9.0.0

  # Utilities
  connectivity_plus: ^6.0.0
  uuid: ^4.3.0
  sentry_flutter: ^8.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.15.0
  riverpod_generator: ^2.3.0
  flutter_lints: ^3.0.0
```

### Minimum Versions

- **Flutter**: >= 3.19.0 (stable channel)
- **Dart**: >= 3.2.0
- **iOS**: >= 12.0
- **Android**: >= API 21 (Android 5.0)

---

## 2. Project Structure

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp setup
│
├── src/
│   ├── core/
│   │   ├── errors/                    # Typed error classes
│   │   │   ├── app_error.dart
│   │   │   ├── network_error.dart
│   │   │   └── sync_error.dart
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   └── utils/
│   │       ├── logger.dart
│   │       └── retry.dart
│   │
│   ├── database/
│   │   ├── database.dart              # Main Drift database
│   │   ├── database.g.dart            # Generated
│   │   └── tables/
│   │       ├── domains_table.dart
│   │       ├── skills_table.dart
│   │       ├── questions_table.dart
│   │       ├── attempts_table.dart
│   │       ├── sessions_table.dart
│   │       ├── skill_progress_table.dart
│   │       ├── outbox_table.dart
│   │       └── sync_meta_table.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── providers/auth_provider.dart
│   │   ├── curriculum/
│   │   │   ├── domain_list_screen.dart
│   │   │   ├── skill_list_screen.dart
│   │   │   └── providers/
│   │   ├── practice/
│   │   │   ├── practice_screen.dart
│   │   │   ├── question_runner.dart
│   │   │   └── widgets/
│   │   │       ├── multiple_choice_widget.dart
│   │   │       ├── mcq_multi_widget.dart
│   │   │       ├── text_input_widget.dart
│   │   │       ├── boolean_widget.dart
│   │   │       └── reorder_steps_widget.dart
│   │   ├── progress/
│   │   │   └── progress_screen.dart
│   │   └── sync/
│   │       └── sync_service.dart
│   │
│   ├── repositories/
│   │   ├── domain_repository.dart
│   │   ├── skill_repository.dart
│   │   ├── question_repository.dart
│   │   ├── attempt_repository.dart
│   │   └── skill_progress_repository.dart
│   │
│   └── services/
│       ├── auth_service.dart
│       ├── connectivity_service.dart
│       └── scoring_service.dart
```

---

## 3. Database Setup (CRITICAL)

### 3.1 Platform Detection Pattern (REQUIRED)

**CRITICAL**: ALWAYS use platform detection. NEVER hardcode platform.

```dart
// lib/database/database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

LazyDatabase _openConnection() {
  // CRITICAL: Check platform first
  if (kIsWeb) {
    // Web platform: Browser testing only (development)
    // Production apps are native Mac/Windows
    return LazyDatabase(() async => driftDatabase());
  } else {
    // Native platform: Production Mac/Windows apps
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      return NativeDatabase(file);
    });
  }
}

@DriftDatabase(tables: [
  Domains,
  Skills,
  Questions,
  Attempts,
  Sessions,
  SkillProgress,
  Outbox,
  SyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

**Agent Checklist**:
- [ ] Platform detection uses `kIsWeb` (never hardcode)
- [ ] Web path uses `driftDatabase()` (testing only)
- [ ] Native path uses `NativeDatabase` with file (production)
- [ ] Comments clarify web = testing, native = production

### 3.2 Table Definitions (Drift)

#### Domains Table

```dart
// lib/database/tables/domains_table.dart
import 'package:drift/drift.dart';

class Domains extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();
  TextColumn get status => text()();  // 'draft' or 'live'
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Skills Table

```dart
class Skills extends Table {
  TextColumn get id => text()();
  TextColumn get domainId => text().named('domain_id')();
  TextColumn get slug => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get difficultyLevel => integer().named('difficulty_level')();
  IntColumn get sortOrder => integer().named('sort_order')();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Questions Table

```dart
class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get skillId => text().named('skill_id')();
  TextColumn get type => text()();  // question_type enum
  TextColumn get content => text()();
  TextColumn get options => text()();  // JSON string
  TextColumn get solution => text()();  // JSON string
  TextColumn get explanation => text().nullable()();
  IntColumn get points => integer()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Attempts Table

```dart
class Attempts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get questionId => text().named('question_id')();
  TextColumn get response => text()();  // JSON string
  BoolColumn get isCorrect => boolean().named('is_correct')();
  IntColumn get scoreAwarded => integer().named('score_awarded')();
  IntColumn get timeSpentMs => integer().nullable().named('time_spent_ms')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Outbox Table (Client-Side ONLY)

```dart
class Outbox extends Table {
  TextColumn get id => text()();
  TextColumn get tableName => text().named('table_name')();
  TextColumn get action => text()();  // INSERT, UPDATE, DELETE, UPSERT
  TextColumn get recordId => text().named('record_id')();
  TextColumn get payload => text()();  // JSON string
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get syncedAt => dateTime().nullable().named('synced_at')();
  TextColumn get errorMessage => text().nullable().named('error_message')();
  IntColumn get retryCount => integer().named('retry_count')();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### SyncMeta Table

```dart
class SyncMeta extends Table {
  TextColumn get tableName => text().named('table_name')();
  DateTimeColumn get lastSyncedAt => dateTime().named('last_synced_at')();
  IntColumn get syncVersion => integer().named('sync_version')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {tableName};
}
```

### 3.3 Code Generation

```bash
# Generate Drift code
dart run build_runner build --delete-conflicting-outputs

# Watch mode (development)
dart run build_runner watch --delete-conflicting-outputs
```

---

## 4. Core Patterns

### 4.1 Riverpod Provider Pattern

#### Database Provider

```dart
// lib/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/src/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
```

#### Repository Provider

```dart
// lib/repositories/domain_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final domainRepositoryProvider = Provider<DomainRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DomainRepository(db);
});

class DomainRepository {
  final AppDatabase db;

  DomainRepository(this.db);

  // Get all published (live) domains
  Future<List<Domain>> getAllDomains() {
    return (db.select(db.domains)
      ..where((d) => d.status.equals('live'))
      ..where((d) => d.deletedAt.isNull())
      ..orderBy([(d) => OrderingTerm.asc(d.sortOrder)]))
      .get();
  }

  // Get domain by ID
  Future<Domain?> getDomainById(String id) {
    return (db.select(db.domains)
      ..where((d) => d.id.equals(id)))
      .getSingleOrNull();
  }

  // Upsert domain (from sync)
  Future<void> upsertDomain(Domain domain) {
    return db.into(db.domains).insertOnConflictUpdate(domain);
  }
}
```

#### State Provider

```dart
// lib/features/curriculum/providers/domain_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/domain_repository.dart';
import '../../../database/database.dart';

final domainsProvider = FutureProvider<List<Domain>>((ref) async {
  final repo = ref.watch(domainRepositoryProvider);
  return repo.getAllDomains();
});
```

---

**END OF STUDENT_APP_COMPLETE.md**