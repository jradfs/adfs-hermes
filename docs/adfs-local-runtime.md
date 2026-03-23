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

## Notes

- `adfs-hermes` uses `HERMES_HOME=~/.adfs-hermes`
- the default terminal backend remains Docker
- runtime state is separate from `~/.hermes`
- this fork should be the home for ADFS-specific runtime improvements
