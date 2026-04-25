# ADR-001: Represent User Interactions as Events

_Status_: Accepted
_Context_: Harassment detection requires analyzing patterns over time. A simple "user-to-user state" model loses temporal resolution and makes reprocessing difficult.

_Decision_: All Discord messages will be modeled as immutable interaction events. Classification output is not embedded directly into the base interaction record; it is stored as a separate immutable classification record keyed by `message_id` and `classifier_version`.

_Schema (logical)_:

- message_id
- server_id
- channel_id
- author_id
- target_user_ids
- timestamp
- raw_content
- classification_status
- content_retention_expires_at

_Related classification record_:

- message_id
- classifier_version
- classification (JSON)
- severity_score
- confidence
- classified_at

_Consequences_:

- Enables reprocessing with improved models
- Supports time-based analysis and decay
- Increased storage footprint
- Keeps ingestion separate from classification lifecycle
