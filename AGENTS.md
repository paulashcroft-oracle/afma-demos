<!-- codex-projects-shared-guidance:v1 -->
# AFMA Demos Instructions

Read `../AGENTS.md` first. It is the canonical shared instruction file for every project under `Codex Projects`.

This file contains only project-specific additions or explicit exceptions. Shared rules belong in the parent or routed standards, not in this file.

## AFMA Demo Notes

- This repo holds the AFMA CAAB demo's database source, APEX exports, runbooks, readiness checks, and integration assets.
- AI Hub task `ai-hub-092` is the onboarding record for this project.
- The documented AIDEMODB workspace/schema is `AFMA`; app creation and verification evidence is in `runbooks/afma-caab-demo-build.md`.
- The current AIDEMODB application is app `101`, `AFMA CAAB AI Demo`, alias `AFMA-CAAB-AI-DEMO`.
- AIDEMODB AI Hub uses the application-based project key `caab` for app `101`. Use `codex-caab`, not `codex-afma`, for the CAAB Kanban, tasks, task bundles, System Designs, and application feedback/API work.
- Keep schema name, application IDs, runtime URLs, builder links, AI Hub project keys, and credential filenames precise once they are confirmed; do not guess them into source files.
- The build runbook's June 2026 ASHCROFT `/projects/afma/feedback` bridge is historical. App `101` now maps to AIDEMODB project `caab`; this mapping alone does not prove that the installed forwarder, endpoint config, or feedback Web Credential has migrated. Resolve that state in a separately approved bridge task before activating forwarding.

## Local Workflow

- Keep verified source scripts, runbooks, readiness checks, and dated exports in git.
- Leave unrelated local changes untouched unless explicitly asked.
- Use PRs for substantial verified changes into `main`.

## Project Credential References

- `Shared Credentials\logins\afma-geoscience-demo-user.local.json`
- `Shared Credentials\api-keys\ai-hub\codex-caab-aidemodb.local.json` — AIDEMODB app `101` / AI Hub project `caab`
- `Shared Credentials\api-keys\ai-hub\codex-afma.local.json` — legacy ASHCROFT source only; never use or repoint it for AIDEMODB
