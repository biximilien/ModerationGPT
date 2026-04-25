# ADR-012: Classification Pipeline Delivery Semantics

_Status_: Accepted
_Context_: The system stores immutable interaction events, classifies them asynchronously, and derives read models from classification results. Without explicit delivery semantics, retries, duplicates, and reprocessing behavior will drift into ad hoc implementation.

_Decision_: The classification pipeline will use explicit idempotent state transitions keyed by `message_id` and `classifier_version`.

_Classification lifecycle_:

- `pending`: interaction event stored, classification not yet completed
- `classified`: authoritative classification record stored
- `failed_retryable`: transient failure, eligible for retry
- `failed_terminal`: permanent failure after retry exhaustion

_Rules_:

- Enqueue at most one active classification job per `message_id` and `classifier_version`
- Worker execution must be idempotent for the same `message_id` and `classifier_version`
- Retries use bounded exponential backoff
- Projection updates must also be idempotent and keyed by `message_id` and `classifier_version`
- Reprocessing is performed by re-enqueueing stored interaction events with a new `classifier_version`, not by mutating old classification records

_Operational requirements_:

- Failed records must remain queryable for operational review
- Replays must not overwrite historical classifications from prior versions
- The synchronization boundary between event storage and derived projections is the stored classification record

_Consequences_:

- Makes eventual consistency operationally predictable
- Supports safe replay when prompts or schemas change
- Requires explicit status tracking and idempotency controls
