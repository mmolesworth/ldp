# EMPLOYEE_DIRECTORY  *(build-support — interim; R1 / D-1)*

> ## ⛔ WITHDRAWN — 2026-07-26
>
> `EMPLOYEE_DIRECTORY` is retired. Personnel and supervisor-chain data comes from
> an existing system of record (dependency **D-1**); the interim SharePoint list
> was never part of the intended design and is no longer built, provisioned or
> read by any screen.
>
> Kept as the record of a superseded decision. Do not implement.
>
> **What replaced it:** until the D-1 integration exists, personnel fields on the
> Application Screen are entered by hand (RQ003), and DTD assigns reviewers after
> submission rather than the app snapshotting a supervisor chain (R1/R5).


**Purpose:** Personnel + supervisor-chain source read by the app (no premium connector — the app
only reads a SharePoint list). Loaded/refreshed by the maker outside the app (**mechanism deferred,
T077**). Manual entry remains the fallback when a record is absent (RQ003).
**Anchors:** RQ002–003, RQ015–017; research R1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| Email | Single line of text | Yes | Identity key; **indexed**. |
| EmployeeName | Single line of text | Yes | → `ApplicationName`. |
| Location | Single line of text | No | |
| Grade | Single line of text | No | |
| JobSeries | Single line of text | No | |
| JobTitle | Single line of text | No | |
| FirstLineSupervisorEmail | Single line of text | No | |
| SecondLineSupervisorEmail | Single line of text | No | Empty → no second line (OI-6 / FR-012a path). |

**Indexes:** `Email`.
**Note:** interim source pending the final HR Links decision (D-1). Seed test data including one
employee with **no** second-line supervisor to exercise FR-012a.
