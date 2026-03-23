---
name: adfs-firm-cli
description: ADFS firm CRM and knowledge workflow for adfs-hermes using the compact adfs-firm CLI lane inside Docker. Use when the user asks to find a client, inspect CRM context, list tasks or projects, check deadlines, read memory, search firm knowledge, or perform guarded firm writes. Prefer this over raw database/admin access for normal firm operations.
version: 1.0.0
author: ADFS
license: MIT
metadata:
  hermes:
    tags: [ADFS, CRM, Firm, Supabase, CLI]
    related_skills: [adfs-qbo-cli]
---

# ADFS Firm CLI

Use the Docker-mounted `adfs-firm` wrapper for normal firm operations.

Primary command:

```bash
/pilot/bin/adfs-firm
```

If the wrapper seems missing, run:

```bash
/pilot/bin/adfs-tools-info
```

## When to use

- client search
- client dashboard and context
- contacts, projects, tasks, deadlines
- firm knowledge and memory
- safe note or memory updates
- operational CRM work that should not use raw SQL/admin tools

## Default workflow

1. Read first.
2. Search or identify the correct client.
3. Pull only the minimum needed context.
4. For writes, keep the guarded-write posture.
5. Re-read after writes and summarize the outcome.

## Common commands

Health:

```bash
/pilot/bin/adfs-firm health
/pilot/bin/adfs-firm tools
```

Client lookup:

```bash
/pilot/bin/adfs-firm client find --query "Tequilas"
/pilot/bin/adfs-firm client info --entity-id <uuid>
/pilot/bin/adfs-firm client dashboard --entity-id <uuid>
```

Tasks, projects, deadlines, memory:

```bash
/pilot/bin/adfs-firm task list --entity-id <uuid> --limit 20
/pilot/bin/adfs-firm project list --entity-id <uuid> --limit 20
/pilot/bin/adfs-firm deadline list --entity-id <uuid> --limit 20
/pilot/bin/adfs-firm memory get-context --entity-id <uuid> --limit 5 --include-archived
```

## Write safety rules

- Prefer read commands before any write.
- Do not use raw database admin tools for normal firm work.
- For write commands, require explicit intent.
- Use guarded flags like:

```bash
--confirm-write
--actor-user-id jr@adfs.tax
--actor-role admin
--actor-email jr@adfs.tax
```

- After a write, re-read the affected record and report what changed.

## Output hygiene

- Prefer client names, statuses, dates, and summaries over internal UUIDs.
- Only surface IDs when needed for the next command or when the user asks.
- Keep the user-facing answer concise and operational, not database-shaped.
