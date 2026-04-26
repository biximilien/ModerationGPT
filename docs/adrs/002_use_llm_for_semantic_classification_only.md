# ADR-002: Use LLM for Semantic Classification Only

_Status_: Accepted
_Context_: LLMs are probabilistic and non-deterministic. Using them directly for moderation decisions introduces instability and explainability issues.

_Decision_: Use OpenAI GPT-4o strictly as a classifier producing structured output. All scoring and enforcement logic will be deterministic and implemented in application code.

_Output Schema (authoritative)_:

- intent: neutral | friendly | teasing | aggressive | abusive | threatening
- target_type: individual | group | self | none
- toxicity_dimensions:
  - insult: boolean
  - threat: boolean
  - harassment: boolean
  - profanity: boolean
  - exclusion: boolean
- severity_score: float (0-1)
- confidence: float (0-1)

_Constraints_:

- Responses must be schema-bound JSON only
- Long-lived classifier records must avoid free-form rationale text unless a later privacy and review-surface decision explicitly permits it
- Prompts must be deterministic and versioned
- Classification output is advisory input to the scoring engine, not a moderation decision

_Consequences_:

- Deterministic behavior in moderation decisions
- Easier to audit and debug
- Requires prompt engineering and schema validation
