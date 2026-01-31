# PLAYBOOKS.md

## Agent Playbooks

**Purpose**: Quick-reference recipes for common agent tasks. Reduces errors and ensures consistency.

### Schema Change
**When**: Adding a new table, column, or constraint.
**Steps**:
1. Update `AppShell/docs/SCHEMA.md` first (reference section).
2. Create migration in `supabase/migrations/`.
3. Update RLS policies if needed.
4. Run `make db_migrate`.
5. Verify with `make db_verify_rls`.
**Pitfalls**: Forget `updated_at`/`deleted_at` on syncable tables. Always check against offline-first rule.

### RLS Policy Change
**When**: Modifying access rules for any table.
**Steps**:
1. Update policies in `AppShell/docs/SCHEMA.md`.
2. Apply via migration.
3. Test with `make db_verify_rls`.
4. Manual test: Try access as student vs admin.
**Pitfalls**: Policies can break existing queries. Test both roles.

### Add RPC Function
**When**: New server-side logic needed (e.g., batch operations).
**Steps**:
1. Define in `AppShell/docs/SCHEMA.md` (RPC section).
2. Create migration for the function.
3. Update `AppShell/docs/specs/API_SPEC.md` with endpoint details.
4. Test via Supabase dashboard or client call.
**Pitfalls**: Forget `SECURITY DEFINER`. Ensure idempotent.

### Offline Sync Behavior Change
**When**: Modifying how data syncs between client and server.
**Steps**:
1. Update sync logic in `AGENTS.md` code patterns.
2. Ensure outbox processing handles the change.
3. Test conflict resolution.
4. Update `PHASE_STATE.json` with notes.
**Pitfalls**: Breaking idempotency. Not handling network failures.

### New Question Type
**When**: Adding support for a new question format.
**Steps**:
1. Update enum in `AppShell/docs/SCHEMA.md`.
2. Update client parsing logic.
3. Update UI components.
4. Test scoring and validation.
**Pitfalls**: Forgetting to update all clients (student + admin).

### Dependency Update
**When**: Updating a locked library version.
**Steps**:
1. Check `AGENTS.md` for version constraints.
2. Update manifests (pubspec.yaml, package.json).
3. Run full CI: `make ci`.
4. Test on target platforms.
**Pitfalls**: Breaking changes in minor versions. Not updating all related files.

### Error Handling Addition
**When**: Adding new error types or recovery logic.
**Steps**:
1. Define in `AppShell/docs/specs/API_SPEC.md` (Error Codes).
2. Implement in client code.
3. Add retry/backoff if applicable.
4. Test error paths.
**Pitfalls**: Silent failures. Not user-friendly messages.

### Realtime Subscription
**When**: Adding live updates for data changes.
**Steps**:
1. Define channel in `AppShell/docs/specs/API_SPEC.md`.
2. Implement client subscription.
3. Handle reconnections.
4. Test with manual DB changes.
**Pitfalls**: Not handling auth token refresh. Over-subscribing.

### Migration Rollback
**When**: Need to undo a migration.
**Steps**:
1. Create down migration if possible.
2. Restore from backup if not.
3. Update `PHASE_STATE.json` to reflect rollback.
4. Re-run validations.
**Pitfalls**: Data loss. Not updating state.

### Phase Validation Failure
**When**: `make validate_phase_N` fails.
**Steps**:
1. Check error output.
2. Fix root cause (code, docs, or environment).
3. Re-run validation.
4. If stuck, update `PHASE_STATE.json` blocked_on.
**Pitfalls**: Ignoring failures. Proceeding without validation.