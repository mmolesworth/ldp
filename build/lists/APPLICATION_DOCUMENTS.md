# APPLICATION_DOCUMENTS

**Purpose:** One row per required supporting document, each holding that document as its own
attachment. Join of APPLICATIONS × document type.
**Anchors:** RQ009; FR-006; Constitution VII (Records Retention).

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | SharePoint auto-number (Counter). |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Owning application. **Indexed at creation** — see below. |
| DocumentType | Choice | Yes | Resume, Statement of Interest, Performance Appraisal. |
| *(Attachments)* | built-in | No | Exactly one file per row, by convention. |

**Indexes:** `ApplicationID`, `DocumentType`.

## Why a row per document rather than one attachment collection

`APPLICATIONS` item attachments are a single unnamed collection. There is no way to tell a resume
from a statement of interest, so DTD cannot report which of the three is missing and an applicant
cannot replace one without touching the others. A row per type gives each slot an identity, and
the type is data rather than a column — a fourth required document later is a new choice value,
not a schema change.

**Three rows are created with the draft**, not on upload. An attachment needs a row to attach to,
so the rows must exist before the Attachments control has anything to bind to.

## What this does NOT solve

**No file-type or size enforcement.** The canvas Attachments control has neither an extension
filter nor a size property. PDF/Word and size limits require a Power Automate flow inspecting the
file after upload — deferred (OI-ARCH-1). This is true of every option considered; it is not a
consequence of this structure.

## Retention (Constitution VII)

SharePoint list attachments **cannot carry retention labels, cannot be versioned and cannot be
tiered.** Principle VII requires the seven-year archive to preserve supporting documents, which
attachments give no mechanism to satisfy. The intended end state is a document library with these
same two metadata columns and a flow moving files out of the attachment; the columns match so that
migration is a move rather than a redesign.

Deferred deliberately — see **OI-ARCH-1**. At 200 applications/year this list reaches roughly
4,200 rows and 8 GB over the retention period.

**Index `ApplicationID` at creation.** Adding an index to a list already past 5,000 items is
painful and sometimes requires emptying it.
