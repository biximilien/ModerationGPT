# ADR-009: Context-Aware Classification

_Status_: Accepted
_Context_: Message meaning depends on surrounding context.

_Decision_: Include limited context in classification:

- previous N messages in channel
- recent interactions between users

_Consequences_:

- Improved accuracy
- Increased token usage and cost
- More complex prompt construction
