# ADR-005: Separate Event Storage from Aggregated State

_Status_: Accepted
_Context_: Raw events and derived relationship metrics serve different purposes and evolve differently.

_Decision_: Maintain:

- Event store (immutable interaction records)
- Derived store (relationship edges and scores)

_Consequences_:

- Supports recomputation when models change
- Increases system complexity
- Requires synchronization strategy
