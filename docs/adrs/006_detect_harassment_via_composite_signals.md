# ADR-006: Detect Harassment via Composite Signals

_Status_: Accepted
_Context_: Single-message toxicity is insufficient to define harassment.

_Decision_: Compute harassment likelihood using multiple signals:

- asymmetry (A -> B vs B -> A)
- persistence (over time windows)
- burst intensity (short-term spikes)
- target concentration (same victim repeatedly)
- average severity

_Consequences_:

- More accurate detection
- Requires tuning and calibration
- Harder to explain without tooling
