# ADR-008: Asynchronous Classification Pipeline

_Status_: Accepted
_Context_: LLM calls are slow and rate-limited.

_Decision_: Process classification asynchronously:

- Ingest message -> enqueue job
- Worker calls GPT-4o
- Store classification result
- Track job state durably enough to support retries, deferrals, and operational review

_Ownership_:

- Core platform owns queueing, retries, and durable status tracking
- Plugins consume the resulting classification records and update their own projections
- Worker implementation details and transitional allowances are defined in ADR-021

_Consequences_:

- Non-blocking message handling
- Eventual consistency
- Requires durable job state and background execution infrastructure; this may start as an in-process worker and later move to Sidekiq or equivalent
