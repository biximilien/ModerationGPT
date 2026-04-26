# Harassment Postgres Cutover

This runbook is the intended path for moving the harassment pipeline from Redis-backed durable state to the mixed Postgres cutover path.

## Goal

Use Postgres for the durable harassment pipeline core:

- interaction events
- classification records
- classification jobs

while leaving cache and rate-limiting on Redis during the migration phase.

## Preconditions

- `DATABASE_URL` points to the target Postgres database
- the schema in `db/harassment/001_initial_schema.sql` has been applied
- Redis still contains the active harassment runtime state
- the bot is still running with `HARASSMENT_STORAGE_BACKEND=redis`

## Sequence

1. **Apply the schema**

   Make sure the Postgres database has the harassment tables and indexes from:

   - `db/harassment/001_initial_schema.sql`

2. **Bootstrap existing Redis state**

   Run:

   ```bash
   ruby scripts/bootstrap_harassment_postgres.rb
   ```

   This copies:

   - interaction events
   - classification records
   - classification jobs

   into Postgres.

3. **Verify Redis and Postgres counts**

   Run:

   ```bash
   ruby scripts/verify_harassment_postgres.rb
   ```

   Confirm that totals and per-server counts match for:

   - `interaction_events`
   - `classification_records`
   - `classification_jobs`

4. **Pause and sanity-check**

   Before flipping the runtime, confirm:

   - the verification output reports `matches=true` for all three data sets
   - Postgres connectivity is stable
   - logs are clean

5. **Flip the backend**

   Set:

   ```bash
   HARASSMENT_STORAGE_BACKEND=postgres
   ```

   and restart the bot.

6. **Observe after cutover**

   Watch for:

   - successful ingestion of new interaction events
   - successful job progression from `pending` to `classified`
   - expected moderator query behavior
   - absence of repeated job failures

## Rollback

If the Postgres cutover misbehaves:

1. set `HARASSMENT_STORAGE_BACKEND=redis`
2. restart the bot
3. keep Postgres data for investigation; do not delete it immediately

Because Redis remains the operational source before cutover and cache/rate-limit state stays there during the mixed phase, rollback is only a configuration change plus restart.

## Notes

- The bootstrap script is idempotent for already-migrated durable records.
- The verification script is count-based, not a full row-by-row diff.
- Cache and rate-limit repositories are intentionally still Redis-backed in this phase.
