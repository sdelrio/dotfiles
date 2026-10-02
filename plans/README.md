# plans/

Execution plans for agents, **committed to git** (shared across machines) but
**never stowed** (ignored via `.stow-local-ignore`) — they never get symlinked
into `$HOME`.

## Conventions

- File name: `YYYY-MM-DD-<short-slug>.md`
- Front matter: `title`, `date` (execution status is NOT stored here)
- Body sections: `Context`, `Findings`, `Design`, `Steps`, `Verification`,
  `Notes / trade-offs`
- Plans must be **self-contained**: another agent (different model, no shared
  conversation) should be able to execute them without extra research.
- **Per-machine execution status** lives in `status/<hostname -s>.md`
  (e.g. `status/mbp19i1.md`). Each machine only edits its own file — no
  merge conflicts, and every machine can see where each plan stands.
  Format: one line per plan: `- <plan-file-slug>: pending | executing | done | abandoned`
- Keep finished plans for reference or delete at will.

## Executing a plan

Any agent on any machine can execute a pending plan with:

> Read `plans/<plan-file>.md` and execute it end to end, following
> `plans/README.md`.

In opencode, the `/plans` command (`.opencode/command/plans.md`) executes all
pending plans one by one, or a single one via `/plans <slug>`.

Protocol:

1. Read the plan file fully before changing anything.
2. Set the plan to `executing` in your machine's `status/<hostname -s>.md`
   (create the file if it's this machine's first plan) and commit it.
3. Re-verify `Findings` only if they look stale; otherwise trust them.
4. Follow `Steps` in order, then run everything under `Verification`.
5. Set the plan to `done` (or `abandoned` with a reason) in your machine's
   status file and commit (Conventional Commits, e.g. `chore(plans): ...`).
