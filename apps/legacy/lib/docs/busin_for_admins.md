# BusIn for Admins

![Intro – BusIn also serves the school staff and administration](https://raw.githubusercontent.com/Joel-Fah/busin/refs/heads/main/assets/images/docs/busin_for_admins.png)

[Jump to: Onboarding & roles](#onboarding--roles) • [Operational workflows](#operational-workflows) • [Approval states](#approval-states-reference) • [Passes & pricing policy](#passes--pricing-policy) • [Troubleshooting](#troubleshooting) • [Appendix](#appendix)

## Why BusIn helps admins
BusIn streamlines campus transport operations—reducing no‑shows, improving capacity planning, and giving you real‑time oversight of vehicles, routes, and demand.

## Key capabilities
- Live operations board: vehicles, occupancy, ETAs, and incidents
- Seat management: block rows, set capacity, or enable free seating
- Route & schedule planning with templates and exceptions (holidays, exams)
- Digital ticketing with QR validation and fraud controls
- Notifications: service alerts, detours, and targeted messaging
- Analytics: utilization, on‑time performance, demand heatmaps
- Policy controls: eligibility (student/staff), pickup windows, and priorities
- Roles & permissions for dispatchers, planners, and auditors

## Onboarding & roles
Set up the right access for team members before they start operating:

- Roles: Admin, Staff (dispatchers, validators), and read‑only Auditor
- Permissions: approvals, messaging, capacity edits, and exports
- Identity: sign in with institutional Google accounts (`@ictuniversity.edu.cm`)
- Security: enforce least privilege and rotate shared devices

### Boarding policy checklist
- [x] Define eligibility (students, staff, guests)
- [x] Set pickup windows and grace periods
- [x] Create seat blocks for accessibility zones
- [x] Configure notification rules (delays, detours)
- [ ] Publish semester term dates and blackout periods
- [ ] Review data retention and export settings

## Operational workflows
1. Plan routes and time bands; publish changes with versioning.
2. Configure seat rules (capacity, blocks, accessibility zones).
3. Monitor live trips; respond to delays and send alerts.
4. Validate tickets at boarding; reconcile exceptions.
5. Review daily reports; adjust supply to demand trends.

## Approval states reference
| State      | Admin/Staff action       | Target SLA* | Notes                                      |
|:-----------|:--------------------------|:------------|:-------------------------------------------|
| pending    | Review receipt and details| < 24h       | Auto‑expire if missing docs after 7 days   |
| approved   | None                      | immediate   | QR enabled; visible to validators          |
| rejected   | Provide reason            | immediate   | Student notified; can resubmit             |
| expired    | N/A                       | at term end | Reapply next term                          |

Link for students to reapply: include a CTA in the rejection message.

*_SLA: Service Level Agreement for processing times._

## Integrations
- Identity: connect to campus SSO or student directories
- Payments: integrate preferred PSPs for passes and single rides
- Hardware: QR validators, turnstiles, or handheld scanners
- Data exports: CSV, secure APIs for BI tools

## Compliance and security
- Fine‑grained access control and audit trails
- Data retention windows and export on request
- PCI‑compliant payment flows via providers; no raw card storage
- Optional PII minimization and anonymized analytics

## Dashboards and reports
- Utilization by route/time, load factors, and peak/off‑peak analysis
- On‑time performance with delay causes
- No‑show rates, cancellation windows, and recovery actions
- Feedback trends and service quality KPIs

## Passes & pricing policy
| Pass type        | Validity           | Base price | Overrides                      |
|:-----------------|:-------------------|:-----------|:-------------------------------|
| Single ride      | One boarding       | 500 XAF    | Route‑level surge/caps         |
| Day pass         | Calendar day       | 1,500 XAF  | Event‑day promotions           |
| Semester pass    | Academic term      | 25,000 XAF | Scholarship or staff discounts |

> Tip: Pair the utilization dashboard with pass uptake to identify where semester passes need marketing or price adjustment.

## Best practices
- Use demand heatmaps to shift capacity before crunch weeks
- Keep seat blocks flexible for accessibility and events
- Automate alerts for recurring detours or construction
- Run pilot changes on a subset of routes and evaluate

## Troubleshooting
- High no‑show rate: tighten booking windows or add reminders
- Over‑capacity trips: add departures or limit duplicates
- Scanner fails offline: enable delayed validation sync
- Missing routes for students: check eligibility rules and roster sync

## Support
Access the Admin Console Help or contact the transport operations lead.

---

## Appendix

### Policy template (JSON)
```json
{
  "eligibility": ["student", "staff"],
  "pickupWindowMinutes": 10,
  "gracePeriodMinutes": 5,
  "accessibilityBlocks": ["front_row", "rear_lowstep"],
  "notifications": {
    "delay": true,
    "detour": true
  },
  "retentionDays": 365
}
```

### Export format (CSV headers)
```
trip_id,route_id,departure_time,capacity,booked,scanned,late_scans
```
