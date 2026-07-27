# PowerLibs Component Map — LDP Application Phase I

**Feature:** `001-ldp-phase-i` | **Generated:** 2026-07-25 (from PowerLibs MCP `list_components`, 107 components)

Chosen components per UI need (Constitution VIII — reuse over primitives). **Classic-compatible
only** (Constitution II). `free` = no subscription; `pro` = requires PowerLibs Pro — where Pro isn't
available, fall back to the noted classic primitives. Rename each to project convention on
transcription.

| UI need | PowerLibs id | Tier | Project name (rename) | Fallback (classic primitives) |
|---|---|---|---|---|
| App shell / left nav | `sidebar-wide-1` | free | `cmpNavSidebar` | `GroupContainer` + `Gallery` of nav items |
| Top header bar | `navigation-bar-1` | pro | `cmpHeaderBar` | `GroupContainer` + `Label` + `Classic/Icon` |
| Primary button | `classic-button-1` | free | `btn…` per use | `Classic/Button` |
| Secondary / cancel button | `outline-button-1` | free | `btn…Secondary` | `Classic/Button` (outlined pattern) |
| Icon button | `classic-icon-button-1` | pro | `btn…Icon` | `Classic/Icon` + transparent `Classic/Button` overlay |
| Text input | `input-1` | free | `txt…` | `TextInput` + separate `Label` |
| Choice dropdown | `shadcn-dropdown-1` | free | `drp…` | `Classic/DropDown` |
| Date field | *(built-in)* | — | `dtp…` | `Classic/DatePicker` |
| Searchable option/lookup | `searchable-lookup` | pro | `cmpProgramLookup` | `Classic/DropDown` filtered |
| People picker (supervisor / alternate) | `people-picker` | pro | `cmpPeoplePicker` | `TextInput` (email) + validation |
| List / data gallery | `gallery-filter-header` | pro | `gal…` | `Gallery@2.15.0` classic template |
| Clean data table | `user-table` | pro | `gal…Table` | `Gallery` w/ column labels |
| Card gallery | `project-gallery-1` | pro | `gal…Cards` | `Gallery` + `GroupContainer` cards |
| Status badge / pill | `pills-badge-1` / `simple-badge-1` | pro | `cmpStatusBadge` | `GroupContainer` (radius) + `Label` |
| Section stepper (application) | `horizontal-stepper` | pro | `cmpSectionStepper` | `Gallery` of step chips |
| Approval/timeline stepper | `vertical-stepper` | pro | `cmpRoutingSteps` | `Gallery` vertical |
| Slide-out details (program option) | `drawer-right-1` | free | `cmpProgramDrawer` | `GroupContainer` overlay + `HtmlViewer` |
| Modal (generic) | `modal-1` | free | `cmpModal` | `GroupContainer` overlay |
| Confirmation modal (destructive) | `confirmation-modal-1` | pro | `cmpConfirmModal` | `modal-1` |
| Success modal | `success-modal-1` | pro | `cmpSuccessModal` | `modal-1` |
| Warning modal (finalize/publish) | `warning-modal-v2-1` | pro | `cmpWarnModal` | `modal-1` |
| Form-submit review modal | `form-submit-modal` | pro | `cmpSubmitReviewModal` | `modal-1` + checklist labels |
| Toast / notification | `toast-1` | free | `cmpToast` | `GroupContainer` + timer |
| Accordion (FAQ / help) | `accordion-1` | free | `cmpAccordion` | `Gallery` expand/collapse |
| Tabs (workspace sections) | `shadcn-tabs-1` | free | `cmpTabs` | `Gallery` of tab buttons |
| Field help tooltip | `help-icon-tooltip` | pro | `cmpHelpTip` | `Classic/Icon` + popover container |

## PRO IS AVAILABLE — confirmed 2026-07-25

The subscription is in place, so **the classic-primitive fallbacks in the table above do not
apply**. Of 107 components, 94 are Pro and all are usable. Prefer the library component over
primitives in every case (Constitution VIII).

### App frame and Home — chosen 2026-07-25

| Need | Component | Tier | Project name |
|---|---|---|---|
| Global navigation (all screens) | `minimal-mega-menu-navbar` | pro | `cmpNavBar` |
| Applicant status — **Draft** | `checklist-progress` | pro | `cmpAppChecklist` |
| Applicant status — **Submitted** | `timeline-progress` | pro | `cmpAppTimeline` |
| Status pill | `pills-badge-1` | pro | `cmpStatusBadge` |
| "Waiting on you" strip | `card-modern-1` | pro | `cmpReviewerCard` |
| Primary CTA | `raised-button-1` | pro | `btnPrimaryCta` |

`checklist-progress` also satisfies **RQ106** (indicate incomplete items without blocking
navigation) directly — it is a checklist with a progress bar and counter, which is precisely what
that requirement describes.

Navigation groups in `cmpNavBar`: **Apply · Review · Administration · Cycle Operations**.

> **Process correction (2026-07-25):** screens 1–7 were hand-authored from `Classic/*` primitives
> without first calling `search_components` / `get_component_details` / `generate_yaml`. That
> violates the mandatory order in `CLAUDE.md` and Constitution VIII. Every screen from the Home
> rebuild onward is generated from the library first, then renamed to project convention. The
> seven existing screens are candidates for retrofit — see T083.

## Notes

- **Constitution II check:** many library items list `hasModernYaml: true` — use each component's
  **classic** composition (`yaml_mode: "classic"`), never a modern-control variant.
- **Accessibility:** whatever the source component, apply the theme tokens and accessible labels;
  a reused component does not exempt a screen from the accessibility checker (Constitution V/VIII).
