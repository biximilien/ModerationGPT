# ADR-003: Model Relationships as Directed Edges

_Status_: Accepted
_Context_: Harassment is often asymmetric. A single shared "relationship" between users obscures directionality.

_Decision_: Represent relationships as directed edges:

_RelationshipEdge(A -> B)_:

- hostility_score
- positive_score
- interaction_count
- last_interaction_at

_Consequences_:

- Captures asymmetry in interactions
- Enables detection of aggressor vs mutual conflict
- Slightly more complex aggregation logic
