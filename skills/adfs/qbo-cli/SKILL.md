---
name: adfs-qbo-cli
description: QuickBooks Online workflow for ADFS Hermes using the compact qbo CLI lane inside Docker. Use when the user asks about QBO, QuickBooks, bookkeeping status, uncategorized transactions, vendor lookups, reports, cleanup work, or safe QBO write previews. Prefer this over direct MCP-style tool schemas in adfs-hermes.
version: 1.0.0
author: ADFS
license: MIT
metadata:
  hermes:
    tags: [ADFS, QBO, QuickBooks, Bookkeeping, CLI]
    related_skills: [adfs-firm-cli]
---

# ADFS QBO CLI

Use the Docker-mounted `qbo` wrapper, not a large direct tool integration.

Primary command:

```bash
/pilot/bin/qbo
```

If the wrapper seems missing, run:

```bash
/pilot/bin/adfs-tools-info
```

## When to use

- QBO / QuickBooks questions
- bookkeeping status checks
- uncategorized transaction review
- vendor or customer lookups
- P&L, balance sheet, trial balance, A/R, A/P, cash flow
- cleanup workflows and safe write previews

## Default posture

1. Read first.
2. Keep output compact.
3. Use company aliases or realm IDs explicitly.
4. For writes, preview first and only apply after clear user approval.
5. Summarize results for the user instead of dumping huge raw JSON.

## Compact command patterns

Health and company context:

```bash
/pilot/bin/qbo companies
/pilot/bin/qbo status --company adfs
/pilot/bin/qbo company-info --company adfs
```

Reports:

```bash
/pilot/bin/qbo report pnl --company adfs --start 2026-01-01 --end 2026-01-31
/pilot/bin/qbo report bs --company adfs --as-of 2026-01-31
```

Research and cleanup:

```bash
/pilot/bin/qbo uncategorized --company adfs --start 2026-01-01 --end 2026-01-31
/pilot/bin/qbo find-vendor --company adfs --name "Sysco"
/pilot/bin/qbo anomalies --company adfs --severity high --limit 25
```

Safe write flow:

```bash
/pilot/bin/qbo write qbo_update_purchase --arg realm_id=... --arg purchase_id=... --arg memo='Preview only'
/pilot/bin/qbo write qbo_update_purchase --apply --arg realm_id=... --arg purchase_id=... --arg memo='Approved change'
```

## Write safety rules

- Never jump straight to `--apply`.
- Preview first.
- Confirm the target company immediately before apply.
- If the command affects bookkeeping data, tell the user exactly what will change.
- After apply, re-read the affected record or status and report the result.

## Output hygiene

- Prefer narrow queries and date ranges.
- Use `head`, `jq`, or targeted report commands to keep output small.
- In user-facing responses, lead with conclusions, not raw command output.
