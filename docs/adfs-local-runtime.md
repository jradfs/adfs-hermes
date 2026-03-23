# ADFS Local Runtime

This fork can be run as a dedicated ADFS-owned Hermes runtime on JR's Mac while
keeping the execution backend Docker-first for safety.

## Goals

- run from a normal Mac terminal with a simple command
- keep a dedicated ADFS Hermes home so memory, sessions, and skills persist
- preserve reusable learnings from earlier local Hermes usage
- keep Docker as the default terminal backend

## Default Local Paths

- repo:
  `/Users/jr/Documents/CodingProjects/adfs-hermes`
- launcher:
  `~/.local/bin/adfs-hermes`
- dedicated runtime home:
  `~/.adfs-hermes`
- sandbox workspace:
  `~/hermes-sandbox`

## Bootstrap

Run:

```bash
cd /Users/jr/Documents/CodingProjects/adfs-hermes
bash ./scripts/bootstrap-adfs-hermes.sh
```

## Daily Use

Run from any normal Mac terminal:

```bash
adfs-hermes status
adfs-hermes doctor
cd ~/hermes-sandbox
adfs-hermes chat
```

## Firm CLI Lane

The default ADFS Hermes local runtime is wired to expose the trusted firm CLIs
inside the Docker container through mounted repos and sandbox wrapper scripts.

Container mounts:

- `/opt/adfs-qbo-mcp`
- `/opt/adfs-firm`
- `/root/.config/adfs`
- `/root/.local/share/opencode/qbo`

Wrapper commands inside the container:

- `/pilot/bin/qbo`
- `/pilot/bin/adfs-firm`
- `/pilot/bin/adfs-tools-info`

Examples from inside Hermes terminal use:

```bash
/pilot/bin/qbo companies
/pilot/bin/adfs-firm health
/pilot/bin/adfs-firm client find --query "ACME"
```

## Notes

- `adfs-hermes` uses `HERMES_HOME=~/.adfs-hermes`
- the default terminal backend remains Docker
- runtime state is separate from `~/.hermes`
- QBO token/session state is persisted under `~/.adfs-hermes/qbo-state`
- this fork should be the home for ADFS-specific runtime improvements
