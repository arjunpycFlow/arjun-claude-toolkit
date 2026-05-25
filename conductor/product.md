# Product Definition

## Name

arjun-claude-toolkit

## Description

Personal Claude Code tooling registry — a central git repo where reusable skills, hooks, and agents live. A `pull.sh` CLI lets the user selectively copy only what a specific project needs.

## Problem

Centralize Claude workflow tooling. Avoid global installs. Allow per-project, on-demand copy of tools so each repo carries only what it uses.

## Target Users

Owner (Arjun) and a small team that reuses the same Claude Code tooling across multiple projects.

## Key Goals

1. Reusable skills/plugins — shareable Claude Code skills, hooks, agents
2. Workflow automation — cut manual toil during dev
3. Explicit, idempotent install model — copy on demand, never link, hooks merge never replace

## Non-Goals

- Global installation of any tool
- Auto-sync after copy (re-pull is explicit)
- Language coverage beyond Python in v1
