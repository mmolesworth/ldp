<!--
SYNC IMPACT REPORT
==================
Version change: 1.1.0 → 1.2.0
Bump rationale: MINOR. Materially changed guidance in Additional Constraints → Naming conventions
  (SharePoint list names). Resolves OI-2 from spec 001-ldp-phase-i. No Core Principle was added,
  redefined, or removed; the change is to a constraint, not a NON-NEGOTIABLE principle.

Modified sections:
  - Additional Constraints → Naming conventions. The single "Data sources: Pascal case" rule was
    split: SharePoint LIST names are now UPPER_SNAKE_CASE (matching docs/LDP_Logical_Data_Model.md,
    e.g. APPLICATION_PROGRAM_CHOICES); COLUMN (field) names remain Pascal case. The prior "Open
    item" flagging the conflict is replaced with a "Resolved" note recording the maker's decision.

Added: none (no new principle or section).
Removed: the "Open item" note under Naming conventions (superseded by the "Resolved" note).

Templates requiring updates:
  - ✅ .specify/templates/plan-template.md — no naming rules hard-coded; defers to constitution.
       No edit required.
  - ✅ .specify/templates/spec-template.md — no hard-coded naming references. No edit required.
  - ✅ .specify/templates/tasks-template.md — no hard-coded naming references. No edit required.
  - ✅ Spec Kit skill files (.claude/skills/speckit-*) — no stale references. No edit required.
  - ⚠ docs/LDP_Logical_Data_Model.md — its own "Open item"/naming note about the upper-snake vs
       Pascal conflict can now be closed to point at this resolution (maker doc edit, non-blocking).

Follow-up TODOs:
  - TODO(UAT_ACCEPTANCE_SIGNATORY): DTD signatory for formal UAT acceptance not yet identified
    (carried from Ratification section, unchanged by this amendment).

Prior amendments:
  - 1.1.0 (2026-07-25): Added Principle VIII. Component Reuse.
  - 1.0.0 (2026-07-25): Initial ratification; canonical location synced from docs/constitution.md
    with 7 principles.
-->
# NCUA OHR Leader Development Program Application Constitution

**Project:** NCUA Office of Human Resources Leader Development Program Application
**ServiceNow record:** RITM0069731
**Scope:** Phase I. The Power Platform application build.

## Core Principles

### I. Grounding in Source Requirements

Every feature specification MUST anchor to at least one identifier in the project's source requirements documents:

- `docs/LDP_Functional_Requirements_Phase_I.md`, requirement IDs `RQ001` through `RQ119`
- `docs/LDP_Use_Cases.md`, use case IDs `UC-1.1` through `UC-5.2`
- `docs/LDP_Logical_Data_Model.md`, list and field names

A single anchor in any one of the three documents satisfies this rule. Reverse traceability is not required. Not every requirement ID must be claimed by a specification.

Content a specification needs that no source document supports MUST be marked **Proposed**. Proposed content may be specified, planned, and reviewed, but MUST NOT be transcribed into the application until DTD confirms it.

The source documents may disagree with each other. A discrepancy MUST be surfaced and resolved during `/speckit.specify` and `/speckit.clarify`. A discrepancy that cannot be resolved there MUST be recorded in the specification as an open item, and MUST NOT be silently settled in favor of one document. An unresolved discrepancy does not block specification.

**Rationale:** The source documents are the accumulated product of requirements and use case work with DTD. Anchoring keeps generated specifications answerable to that work. Marking unsupported content Proposed keeps invention visible instead of letting it enter the build disguised as a requirement.

### II. Fixed Technology Envelope (NON-NEGOTIABLE)

The following are fixed by environment and licensing constraints. They MUST NOT be reconsidered, proposed against, or worked around at any stage:

- Power Apps **canvas** application. Not model-driven. Not Power Apps Code Apps.
- **Classic controls only.** Modern controls MUST NOT be used.
- **SharePoint lists** as the data store. Dataverse MUST NOT be proposed.
- **No premium connectors.**
- Application source is authored as **YAML**, which the maker transcribes into the solution manually.
- **Power Automate flows are built manually by the maker.** The agent produces flow designs and step-by-step construction instructions, never a deployable flow artifact.

**Rationale:** These are external constraints, not preferences. A plan that proposes an alternative produces work that cannot be executed.

### III. Performance at Volume

Every implementation plan MUST address data volume and delegation before it is complete:

- Gallery and query operations SHOULD be delegable. A non-delegable operation MUST be identified in the plan, justified, and bounded by a stated record count it is safe against.
- The plan MUST state how the design behaves as application cycles accumulate across the retention period, and MUST include a retention or archive approach for closed cycles.
- No design may assume the data set stays at the size of a single cycle.

**Rationale:** Canvas over SharePoint has a non-delegable ceiling. An application validated against one cycle will fail against several years of them, and the failure surfaces after acceptance rather than during it.

### IV. Definition of Done

Work moves through three states. They MUST NOT be collapsed.

| State | Who | Meaning |
|---|---|---|
| **Generated** | Agent | YAML, flow instructions, or configuration produced and reviewed. |
| **Verified** | Maker | Transcribed into the dev environment, runs, and observed behavior matches the acceptance criteria. |
| **Accepted** | DTD | Confirmed against the acceptance criteria at formal UAT. |

The agent MUST NOT mark work verified or accepted. A task closes at **verified**. A feature is not releasable until **accepted**. UAT acceptance is a release gate, not a task gate.

Every specification MUST include acceptance criteria stated as observable behavior a person can walk through by hand. A criterion that cannot be evaluated by manual observation is not an acceptance criterion.

**Rationale:** Nothing in this stack is machine-testable from the repository. Manual acceptance criteria are the only executable test the project has. Separating generated from verified prevents the agent from reporting completion of work that exists only as untranscribed text.

### V. Accessibility (NON-NEGOTIABLE)

The application MUST conform to **WCAG 2.1 Level AA** in satisfaction of Section 508.

- The Power Apps accessibility checker MUST be clean before a feature reaches **verified**.
- Every control that conveys meaning MUST carry an accessible label.
- Screen names MUST be plain language, MUST include spaces, and MUST end with the word "Screen," because screen readers announce them.

**Rationale:** Section 508 applies to NCUA as a federal agency. Accessibility defects found after the build are rework, not adjustments.

### VI. Confidentiality Enforced at the Data Layer (NON-NEGOTIABLE)

Confidentiality MUST be enforced by SharePoint permissions, not by the application interface.

- A hidden, disabled, or unnavigable control MUST NOT be treated as an access control in any specification or plan.
- Any specification that restricts who may see data MUST name the permission-layer mechanism that enforces the restriction.
- Interface affordances such as view-only links and withheld sections are usability features. Where the underlying data is confidential, they MUST be backed by permission-layer enforcement.

**Rationale:** A canvas app is not a security boundary. If an account can read the list, it can read the data regardless of what the interface displays. UAT tests what the interface shows. A security review tests what the account can reach.

### VII. Records Retention (NON-NEGOTIABLE)

Application records MUST be retained and retrievable for **seven years**.

- Retention covers supporting documents as well as list items. Resumes, statements of interest, and performance ratings are SharePoint attachments on the application item, and any archive design MUST preserve them.
- Archiving is a performance measure. It MUST NOT delete records inside the retention period.
- Access to archived records MUST satisfy Principle VI. Committee access to full applications is scoped to the cycle being evaluated and MUST NOT extend to prior cohorts.

**Rationale:** Seven years of applications, performance ratings, and resumes is both a records holding and a PII holding. An archive designed only for application performance satisfies neither obligation.

### VIII. Component Reuse

Screens SHOULD be assembled from the project's pre-designed component library rather than built from primitives. A bespoke control MUST be justified in the plan against the absence of a suitable library component.

- Generated component YAML MUST use classic controls. Modern control variants MUST NOT be used, per Principle II.
- Library components MUST be renamed to project convention on transcription. A library-supplied name does not satisfy the naming constraints in Additional Constraints.
- Library components are subject to Principle V without exception. Reuse is not an accessibility exemption.

**Rationale:** The component library encodes layout, behavior, and accessibility decisions already made and reviewed. Rebuilding from primitives discards that work and reintroduces the defects the library exists to prevent. The renaming and classic-control rules keep reused components answerable to the same envelope and naming discipline as bespoke ones, so reuse never becomes a route around Principle II or Principle V.

## Additional Constraints

### Naming conventions

Microsoft's Power Apps code readability guidance governs naming:
https://learn.microsoft.com/en-us/power-apps/guidance/coding-guidelines/code-readability

- **Controls:** camel case, three-character type prefix, then purpose. `txtUserEmailAddress`, `lblApplicantName`, `galApplications`.
- **Control uniqueness:** control names MUST be unique across the application. A control reused across screens takes a short screen-name suffix, for example `galBottomNavMenuHS`.
- **Variables:** camel case. `gbl` prefix for global variables, `loc` prefix for context variables.
- **Collections:** `col` prefix, camel case.
- **Data sources — SharePoint list names:** `UPPER_SNAKE_CASE`, matching the identifiers in `docs/LDP_Logical_Data_Model.md`, for example `APPLICATION_PROGRAM_CHOICES`. A SharePoint list's name becomes its identifier in Power Fx and cannot be renamed from within the application, so list names MUST be settled before any list is created.
- **Data sources — column (field) names:** Pascal case, for example `ApplicantEmail`, `ExpectedDecisionDate`.
- **Screens:** governed by Principle V.

**Resolved (2026-07-25, spec 001-ldp-phase-i, OI-2).** The prior Pascal-case data-source rule conflicted with the upper-snake list names in `docs/LDP_Logical_Data_Model.md`. The maker settled this in favor of the data model: SharePoint **list** names are `UPPER_SNAKE_CASE`; **column** names remain Pascal case. This amendment records that decision so governance and the build agree before list creation.

### Out of scope for the agent

Environment strategy, promotion between environments, deployment, solution management, and organizational change control are handled by the maker and sit outside the agent's scope. Specifications, plans, and task lists MUST NOT include deployment or environment management work.

## Development Workflow

Work follows the spec-kit sequence: `/speckit.constitution`, `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`.

- Discrepancies among source documents are resolved at **specify**, per Principle I.
- Delegation and volume are addressed at **plan**, per Principle III.
- `/speckit.implement` produces YAML and flow construction instructions only. It MUST NOT report anything as deployed.

## Governance

This constitution supersedes other practices for this project. Where a preference and a principle conflict, the principle governs.

### Compliance

`/speckit.analyze` flags constitutional deviations and continues. A flagged deviation MUST be recorded in the affected specification together with its justification.

Principles marked NON-NEGOTIABLE are an exception in one respect. Because they rest on external constraints (licensing, Section 508, federal records retention), no justification can satisfy them. A flagged deviation from a NON-NEGOTIABLE principle MUST be corrected rather than justified.

### Amendment procedure

1. The maker amends the constitution.
2. The version is incremented per the versioning policy.
3. The amendment date is recorded.

Amendments apply **going forward only**. Specifications, plans, and tasks written under a prior version are not re-evaluated against a later one.

### Versioning policy

- **MAJOR:** backward incompatible principle changes, including removal or redefinition.
- **MINOR:** new principles, or materially expanded guidance within an existing principle.
- **PATCH:** clarification and wording.

### Ratification

Ratified by Mark Molesworth as sole approver. No external review was conducted.

**UAT acceptance signatory:** TODO, DTD signatory not yet identified.

---

**Version:** 1.2.0 | **Ratified:** 2026-07-25 | **Last Amended:** 2026-07-25
