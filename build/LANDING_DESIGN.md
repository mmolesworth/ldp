# Landing Screen — structure and rationale

**Status:** design for review, not yet built. Supersedes the Home Screen, which is
demoted to the administration entry page (see *Consequences*).
**Anchors:** RQ101–104, FR-051/052; US13.

---

## The three jobs

| Who | Job | Type | How they arrive |
|---|---|---|---|
| **Applicant** *(primary)* | Decide whether to apply, then apply; afterwards, find out where their application stands | **Conversion** | Direct — this page is their front door |
| **Supervisor** | Endorse a specific application | Navigational | **Deep-linked email** (T076) → straight to the item. In-app path is a fallback |
| **Committee member** | Score the applicants in a program pool | Navigational | No email exists for this. In-app path is their **only** route |
| **DTD admin** | Run the cycle — 11 destinations | Navigational | **This page, every time.** No console, no bookmark, no email |

Only the applicant has a conversion job. Everyone else needs to be *routed*, quickly
and permanently, without competing for hero space.

**Two of the three secondary routes start here, repeatedly.** Only the supervisor
has an alternative (the deep-linked email). Committee members have no email flow at
all, and administrators arrive at this page every working session. Neither can be
served by a band above the footer — a frequent visitor should not scroll the whole
applicant page to reach their work.

So both get an **above-the-fold route in the utility bar**, repeated with
explanation in the role band, repeated again in the footer. Three placements, zero
hero space, no self-identification demanded of anyone.

---

## Structure

```
┌──────────────────────────────────────────────────────────────────────────┐
│  NCUA Leader Development Program                                         │  ① utility
│               Signed in as Mark · For reviewers · For program administrators     │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Apply to the Leader Development Program                                │  ② hero
│   Applications for FY2026 close 14 March. Open to all NCUA employees.     │
│                                                                          │
│         [  Apply Today  ]        See program details                     │
│          ^^ one primary CTA      ^^ low-emphasis secondary               │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│  ⚠ 3 applications are waiting for your endorsement      [ Review them ]   │  ③ conditional
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Your application                    ← replaces ② once submitted        │  ④ conditional
│   ● Submitted  ● First-line  ○ Second-line  ○ …                          │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│   The programs                                                           │  ⑤ body —
│   ┌────────┐  ┌────────┐  ┌────────┐                                     │    applicant
│   │ NEXT   │  │ MDP    │  │ HPP    │                                     │    content only
│   └────────┘  └────────┘  └────────┘                                     │
│                                                                          │
│   What you'll need     ·  Key dates  ·  Eligibility  ·  FAQ              │
├──────────────────────────────────────────────────────────────────────────┤
│   For reviewers                     │  For program administrators                │  ⑥ role band
│   Endorsing or scoring? Go to your  │  Running a cycle? Cycles, options, │
│   review queue.            [ Open ] │  sheets, placement.       [ Open ] │
├──────────────────────────────────────────────────────────────────────────┤
│   Contact  ·  For reviewers  ·  For program administrators  ·  Accessibility      │  ⑦ footer
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Section notes

### ① Utility bar — the fast path for both secondary roles
`Signed in as {User().FullName}` — **not** a "Log in" link. Internal app, SSO, the
visitor is already authenticated.

**Both** `For reviewers` and `For program administrators` sit here, small type, top right.
This is the load-bearing placement, not a courtesy duplicate of the role band:
administrators start every session on this page and committee members have no other
route in, so both need a route that costs no scrolling. The band at ⑥ explains what
is behind each link; this bar is for the person who already knows.

Small type and top-right position keep them out of the applicant's path — the
applicant's eye goes to the hero headline and CTA, not the corner. That is the whole
reason utility nav exists.

### ② Hero — the only primary CTA
Headline states the action in plain language. Subhead carries the deadline and who
it is open to. **`Apply Today`** is the single primary CTA; `See program details`
is a low-emphasis secondary that scrolls to ⑤.

CTA text follows applicant state — `Apply Today` / `Finish your application` — and
the whole hero is replaced by ④ once an application is in flight. One CTA slot,
state-dependent content; never two competing buttons.

Disabled outside an Open cycle, with the reason stated (FR-051). A dead button with
no explanation is the failure mode.

### ③ Reviewer strip — conditional, data-driven
Renders **only** when the signed-in user actually has pending endorsements:

```
Filter(APPLICATIONS,
  Or(FirstLineSupervisorEmail = User().Email,
     SecondLineSupervisorEmail = User().Email))
```

This is **not** role segmentation. NN/g's objection is to making users
self-identify; showing someone their own pending work asks nothing of them. An
applicant never sees it, a supervisor with an empty queue never sees it, and it
needs no role model — so it works before OI-7 lands.

It is **reinforcement, not the mechanism**: the supervisor's real path is the
deep-linked email (T076). Do not let this strip become the reason emails get
deprioritised.

### ④ Application progress — conditional
The PowerLibs `timeline-progress` component, shown only when `Status` is
Submitted / Complete / Incomplete. Drafts show nothing — there is no progress to
show. Finished applications (Placed / Not Selected) show the outcome in ② instead.
Step comes from `RoutingStage`.

### ⑤ Body — applicant content only
No role switching anywhere in this region. Programme cards bind `PROGRAMS`.
The supporting panels — eligibility, what you'll need, FAQ, contact — are
**OI-LAND-1**: the copy does not exist in any source document and inventing
eligibility text on a page applicants act on would be a real harm, not a cosmetic
gap. They ship as marked placeholders until DTD/OHR supply the content.

### ⑥ Role band
Two panels, both prefixed **"For"** per the brief. Committee members are folded
into *For reviewers* alongside supervisors — one destination, because the queue
screen can show whichever work applies to the signed-in user, and two near-identical
panels would be the ambiguity the brief warns about.

This band **explains**; the utility bar ① **routes**. Someone arriving for the first
time reads here what is behind each link; a returning administrator uses the corner
link and never scrolls this far. Both must exist — the band alone would make frequent
visitors scroll the applicant page daily, and the bar alone would leave a first-time
committee member guessing what "For reviewers" contains.

### ⑦ Footer
Full role links repeated, contact, accessibility statement. Guarantees rule 3 —
role links reachable from every page, no dead ends.

---

## Deliberate departures from the source brief

The brief targets consumer marketing sites. Three things do not translate:

1. **`Log in` utility link** — meaningless under SSO. Replaced with identity display.
2. **`Evaluating [App]?` → demo environment** — no product-evaluator audience exists.
   "Evaluator" here means someone evaluating *applications*, inside the app, doing
   assigned work. That slot is repurposed as *For reviewers*.
3. **Proof / objection-handling sections** — the applicant is not choosing between
   vendors. Their objections are factual (eligibility, effort, timing), so this
   region is guidance, not persuasion.

Everything else is kept: one primary CTA above the fold, no role-switcher hero, no
role-based global navigation, "For" prefixes, role links reachable everywhere,
and no dedicated role page unless its content is genuinely unique.

---

## Consequences

**The Home Screen is deleted.** Its applicant timeline moves to ④ here. Its eleven
admin destinations become the target of *For program administrators* — which is a justified
dedicated page under rule 4, since that content is unique and duplicates nothing on
this page. In practice Home is demoted and renamed, not discarded.

That page carries real weight: administrators reach it from this landing page every
session, so it is their working surface, not an occasional detour. It should open
directly onto the eleven destinations with no intermediate step, and it needs a
visible route back here — rule 3, no dead ends.

**`_NavBar.yaml` is retained but unused for now.** The mega-menu is role-based global
navigation, which this design rules out. It is kept because the *administration*
page — a console for one role, reached deliberately — is exactly where a dense menu
does belong.

**Open question — committee assignment.** `COMMITTEE_SCORES.ScoredBy` is written
*after* scoring, so nothing in the data model identifies who *should* score a pool.
Committee members therefore cannot get a data-driven strip like ③; they can only be
routed through ⑥. If members are meant to be assigned to programs, that is a
data-model gap to resolve before Phase 10, not at it.
