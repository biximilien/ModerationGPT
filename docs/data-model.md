# Data Model

ModerationGPT stores moderation state in Redis. Redis keys are defined in `DataModel::Keys`; JSON audit records are defined by `DataModel::KarmaEvent`.

## Keys

### `servers`

- Type: Redis set
- Members: Discord server IDs as strings
- Purpose: tracks servers known to the bot

### `server_{server_id}_users`

- Type: Redis set
- Members: Discord user IDs as strings
- Purpose: stores the per-server moderation watchlist

### `server_{server_id}_karma`

- Type: Redis hash
- Fields: Discord user IDs as strings
- Values: integer karma scores
- Purpose: stores current per-server user karma

### `server_{server_id}_user_{user_id}_karma_history`

- Type: Redis list
- Values: JSON `KarmaEvent` records
- Order: newest first
- Retention: latest 50 entries
- Purpose: stores score changes and automod outcomes for one user in one server

## KarmaEvent

```json
{
  "created_at": "2026-04-20T12:00:00Z",
  "delta": -1,
  "score": -5,
  "source": "automated_infraction",
  "actor_id": 42,
  "reason": "appeal"
}
```

`actor_id` and `reason` are optional. Automod outcome events use `delta: 0` with the current score.

Common sources:

- `automated_infraction`
- `manual_adjustment`
- `manual_reset`
- `automod_log_only`
- `automod_timeout_applied`
- `automod_timeout_unavailable`
- `automod_kick_applied`
- `automod_kick_unavailable`
- `automod_ban_applied`
- `automod_ban_unavailable`
- `automod_skipped_elevated_member`
