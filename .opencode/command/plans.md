---
description: Execute pending plans from plans/ one by one (or a specific plan given as argument)
agent: build
---

Execute plan(s) from the `plans/` directory in this repo, following the
protocol in `plans/README.md`.

If arguments are empty, execute **all pending plans one by one**:

1. Read `plans/README.md` (conventions + execution protocol).
2. List plan files matching `plans/[0-9]*-[0-9]*-*.md` (skip `README.md` and
   `status/`). Read each one fully.
3. Read this machine's status file `plans/status/$(hostname -s).md`; create it
   (with a `# Execution status — <hostname>` header) if missing.
4. Select plans whose status is `pending` or `executing` — oldest first by the
   date in the filename.
5. Execute them one by one. Fully complete each plan — Steps in order, then
   every check under its Verification section — before starting the next.
6. If a plan fails verification or blocks, mark it `abandoned` with a one-line
   reason in the status file, commit, and stop and report which plans remain.

If $ARGUMENTS names a plan file or slug, execute only that plan.

For every executed plan, follow the protocol exactly:

- Before starting: set the plan to `executing` in your machine's
  `plans/status/<hostname -s>.md` and commit (e.g.
  `chore(plans): mark <slug> executing on <hostname>`).
- Trust the plan's `Findings` unless clearly stale; re-verify only what looks
  outdated.
- After success: set the plan to `done` in the status file and commit
  (Conventional Commits, e.g. `chore(plans): <slug> done on <hostname>`).
- Never touch another machine's status file, and never edit plan content
  except to fix stale findings (commit separately if so).
