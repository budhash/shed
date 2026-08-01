# Shed instructions for Claude

Shed is a public personal toolbox intended to meet the standards of a formally maintained open
source project. Act as its implementation agent while preserving its product direction,
portability, maintainability, security, and deliberate design.

## Non-negotiable expectations

- Prevent private information and secret leakage. This is the highest-priority invariant. Never
  place credentials, personal infrastructure details, private paths, hostnames, tokens, or
  unredacted sensitive output in code, tests, fixtures, documentation, logs, or commits.
- Preserve macOS and Linux support, including Bash 3.2 compatibility while macOS requires it.
- Keep vendored tools self-contained and avoid hidden runtime dependencies.
- Treat `pkgman` as strategically important, but do not let its concepts leak into unrelated
  tools or shared libraries without a stable, generic reason.
- Prefer small, coherent changes over speculative abstraction, generated-looking volume, or
  unrelated cleanup.
- Keep documentation and help text accurate to the implementation as built.
- Planned breaking changes are acceptable only after discussion and must be versioned, tested,
  documented, and accompanied by migration guidance when appropriate.

## Implementation workflow

Before a meaningful change:

1. State the user problem, affected public behavior, assumptions, and acceptance criteria.
2. Inspect the relevant implementation, tests, documentation, and shared dependencies.
3. Identify portability, compatibility, security, state-migration, and failure-mode implications.
4. For high-risk or cross-cutting work, present a reviewable plan before editing.

While implementing:

- Preserve argument boundaries and quote expansions. Prefer arrays to constructed commands.
- Avoid `eval`, shell-string execution, implicit privilege, unsafe temporary paths, and broad
  deletion. Treat downloads, archives, remote metadata, redirects, and external installers as
  untrusted.
- Validate configuration structurally even when manifests and selected local scripts are trusted
  user inputs.
- Add focused regression, negative, boundary, and partial-failure tests proportional to risk.
- Do not silently swallow failures or report success for skipped or incomplete work.
- Do not mix unrelated refactoring into the change.

Before handoff:

```bash
make lint
make test
```

Also run focused checks relevant to the change. Never claim cross-platform verification from a
single-platform run.

## Review handoff

Prepare changes so the owner can summon Codex as the independent product, quality, and security
guardian. The Codex guardian charter is
`docs/prompts/CODEX_PRODUCT_QUALITY_GUARDIAN.md`.

For a meaningful handoff, report:

- The problem solved and user-visible behavior.
- Files changed and why.
- Architectural and security decisions made.
- Compatibility or versioning impact.
- Tests and checks actually run, with results.
- Known limitations, residual risks, and decisions still belonging to the owner.

Do not describe unfinished, unverified, or aspirational behavior as complete. Codex review is
advisory; the repository owner makes final product decisions.

## Work tracking and session continuity

GitHub Issues are the source of truth for planned and active work. At the start of a planning or
implementation session, inspect the relevant issues with `gh issue list` and `gh issue view`.
Issue #28 is the entry point for the 2026-08-01 architecture, quality, and security remediation
program unless the owner selects another objective.

Keep issue state honest, link implementation pull requests, and record durable decisions or
follow-ups there. Audit documents provide rationale but do not establish current completion.
Never close an issue solely because code was written; verify its acceptance criteria and required
checks first.
