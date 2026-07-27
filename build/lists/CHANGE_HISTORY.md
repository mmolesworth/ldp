# CHANGE_HISTORY

**Purpose:** Append-only audit trail of consequential changes. `ApplicationID` is a plain Number
(not a Lookup) to preserve the trail. Shown to reviewers; **withheld from applicants** (enforced at
the permission layer — OI-7, deferred; Constitution VI).
**Anchors:** RQ093–095, RQ025/031/068; UC-2.x/3.x.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Number | Yes | Application concerned (ID value, not Lookup). |
| ChangeType | Choice | Yes | Program Recommendation, Completeness Determination, Notification Sent, Placement, Post-Submission Modification, Alternate Designation. |
| ChangedBy | Single line of text | Yes | Who made the change. |
| ChangedDate | Date | Yes | Date/time. |
| Details | Multiple lines of text | No | Description or JSON payload. |

**Indexes:** `ApplicationID`.
**Note:** append-only. `Alternate Designation` type supports **[PROPOSED — FR-012a]**. Withholding
from applicants MUST be a SharePoint permission, not a hidden control (Constitution VI / OI-7).
