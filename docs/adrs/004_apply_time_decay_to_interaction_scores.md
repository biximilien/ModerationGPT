# ADR-004: Apply Time Decay to Interaction Scores

_Status_: Accepted
_Context_: Old interactions should not permanently influence a user's standing.

_Decision_: Apply exponential decay to all interaction-derived scores:

hostility_score = sum(severity * confidence * decay(t))

Where decay(t) = e^(-lambda * delta_t)

_Consequences_:

- Recent behavior is prioritized
- Reduces long-term bias
- Requires tuning lambda
