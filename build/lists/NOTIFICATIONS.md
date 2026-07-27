# NOTIFICATIONS

**Purpose:** Append-only log of notifications sent. `ApplicationID` is a plain Number (not a Lookup)
so the log survives if parent data changes. The app writes rows; **flows send** (deferred, T076).
**Anchors:** RQ055–071; UC-5.1/5.2/3.3.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Number | Yes | Application concerned (ID value, not Lookup). |
| RecipientEmail | Single line of text | Yes | Recipient. |
| NotificationType | Choice | Yes | Pending Action, Advance, Reminder, Disposition. |
| SendOutcome | Choice | Yes | Sent, Failed. |
| SentDate | Date | Yes | Date/time sent. |

**Indexes:** `ApplicationID`.
**Note:** append-only — never update or delete rows. Sending/reminders (repeat each interval, OI-3)
are Power Automate flows built by the maker (Constitution II/IV).
