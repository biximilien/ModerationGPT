# ADR-007: Plugin Implements Its Own Read Model

_Status_: Accepted
_Context_: The system uses a plugin architecture. Each plugin should be self-contained.

_Implementation note_: The current code keeps the public harassment plugin thin. The plugin composes harassment-domain services, including classification, read-model, and query services, rather than implementing those responsibilities directly in the plugin class.

_Decision_: The harassment plugin:

- consumes interaction and classification events provided by the core platform
- maintains its own projection (edges + scores)
- owns its classifier prompt versioning, schema validation, scoring rules, and read-model queries

_Platform responsibilities_:

- Discord event ingestion
- job enqueueing and worker orchestration
- durable storage of raw interaction events and classification records

_Plugin responsibilities_:

- harassment-specific prompt/schema definitions
- derived edge aggregation
- harassment likelihood scoring
- moderator-facing query APIs

_Exposed query API_:

- get_user_risk(user_id)
- get_pair_relationship(user_a, user_b)
- recent_incidents(channel_id)

_Consequences_:

- Strong modularity
- Independent evolution
- Allows other plugins to reuse the same ingestion pipeline
- Potential duplication across plugins if multiple plugins classify similar events
