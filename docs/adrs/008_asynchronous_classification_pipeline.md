# ADR-008: Asynchronous Classification Pipeline

_Status_: Accepted
_Context_: LLM calls are slow and rate-limited.

_Decision_: Process classification asynchronously:

- Ingest message -> enqueue job
- Worker calls GPT-4o
- Store classification result

_Ownership_:

- Core platform owns queueing, retries, and durable status tracking
- Plugins consume the resulting classification records and update their own projections

_Consequences_:

- Non-blocking message handling
- Eventual consistency
- Requires queue infrastructure (e.g., Sidekiq)
