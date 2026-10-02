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
