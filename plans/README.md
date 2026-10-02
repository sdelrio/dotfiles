# plans/

Execution plans for agents, **committed to git** (shared across machines) but
**never stowed** (ignored via `.stow-local-ignore`) — they never get symlinked
into `$HOME`.

## Conventions

- File name: `YYYY-MM-DD-<short-slug>.md`
- Front matter: `title`, `date`, `status: pending | executing | done | abandoned`
- Body sections: `Context`, `Findings`, `Design`, `Steps`, `Verification`,
  `Notes / trade-offs`
- Plans must be **self-contained**: another agent (different model, no shared
  conversation) should be able to execute them without extra research.
- Update `status` when starting/finishing execution. Keep finished plans for
  reference or delete at will.
