# ADR-023: Expose Moderation Insights via Read API

_Status_: Accepted
_Context_: Moderators need visibility into system decisions.

_Decision_:
Expose read endpoints:

- user risk profile
- pairwise relationship metrics
- recent flagged interactions

These expose moderator-safe insight views, not raw event rows.

_Contract_:

- All read operations are scoped to a guild
- Read results are eventually consistent with stored classification records and derived projections
- Read surfaces must make score and classifier versioning visible where relevant
- Read surfaces must not expose raw content unless that exposure is explicitly allowed by the retention and privacy policy
- Channel, user, and time-window filtering are valid read concerns

_Access control_:

- Only authorized moderators or operator systems for the relevant guild may access the read API
- Cross-guild reads must be rejected unless there is an explicit higher-privilege operational role

_Data source_:

- User risk and pairwise metrics come from versioned derived projections
- Recent flagged interactions may come from a persisted incident projection or from durable reconstruction over stored interaction events plus classification records
- Recent flagged interaction surfaces must expose derived incident fields by default and may only include raw-content fields when retention policy explicitly permits it

_Consequences_:

- Enables dashboards and tooling
- Requires consistent aggregation updates
- Must handle access control per guild
- Requires version-aware operator experiences
