# RouteRite — Lead Scoring & Funnel Analytics

A SQL scoring model and a two-part Tableau dashboard built on top of the CRM data from the [RouteRite HubSpot landing page project](https://formsandfunnels.com/projects/project_routerite_hubspot.html) — figuring out which leads actually deserve a call first, and proving it with the numbers instead of a gut feeling.

**Full case study:** https://formsandfunnels.com/projects/project_routerite_data_analytics.html
**SQL:** [routerite_project.sql](https://github.com/mhines-808/project_routerite_data_analytics/blob/main/routerite_project.sql)

---

## What This Is

The HubSpot side of RouteRite proved leads could land cleanly in a CRM with no custom code. But a CRM full of contact records doesn't tell anyone which lead to call first, or whether the leads that look "good" on paper actually move faster than the ones that don't. That's a different problem — not "can data get into the system," but "can I get something useful back out of it."

I exported the real leads from HubSpot (50 backdated contacts + 10 live form submissions), brought them into Postgres, and built a scoring model and a dashboard around them to answer that.

## Dashboards

### Overview
Funnel snapshot, volume by tier, conversion rate by tier, velocity by tier, and a trend of velocity over time.

![RouteRite Overview Dashboard](https://github.com/mhines-808/project_routerite_data_analytics/blob/main/routerite_overview.webp?raw=true)

### Scoring Detail
A score breakdown grid, drop-off vs. converted, and an interactive chart that re-groups velocity by Priority Tier, Fleet Size Range, or Lead Status on the fly via a parameter-driven dropdown.

![RouteRite Scoring Detail Dashboard](https://github.com/mhines-808/project_routerite_data_analytics/blob/main/routerite_detail.webp?raw=true)

## How the Scoring Works

- **Fleet size score** — points based on the lead's reported fleet size range
- **Lead progress score** — points based on lead status *and* whether a quote was actually requested (catching leads that progressed but never had their status manually updated)
- **Total score** = fleet size score + lead progress score
- **Priority tier** (Hot / Warm / Cold) — the total score bucketed with `CASE`

All of it lives in a single Postgres `VIEW` (`leads_scored`), so the scoring logic is written once and every downstream query — SQL or Tableau — just references the view like a normal table.

## Funnel Velocity

`days_to_quote` is calculated straight into the same view via date subtraction (`quote_requested_date - demo_requested_date`), so "how fast does a lead move from demo request to quote request" is just another column, not a separate calculation to remember.

## Tech Stack

- **PostgreSQL** — scoring model, CASE logic, CTEs, view
- **Tableau** — dashboards, calculated fields, parameters
- **HubSpot** — source CRM data (see the [companion project](https://formsandfunnels.com/projects/project_routerite_hubspot.html))

## Key Decisions

- **Built the scoring logic as a view instead of repeating CASE statements in every query** — write it once, query it everywhere after.
- **Caught a gap in my own scoring logic before locking it in** — the first version of the progress score only checked Lead Status, which missed leads that had requested a quote but never had their status touched by a rep. Added a second condition that checks for a quote-requested date directly.
- **One interactive chart with a parameter instead of three static ones** — velocity by tier, by fleet size, and by lead status are three lenses on the same question, so one chart with a dropdown does the work of three.
- **Split into two linked dashboards** instead of one long scroll — a summary view and a more exploratory detail view, connected by a nav button, so each one stays focused.

---

*Part of a self-directed SQL/Tableau portfolio build. See [formsandfunnels.com](https://formsandfunnels.com) for the full portfolio.*
