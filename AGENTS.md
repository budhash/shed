# Shed instructions for Codex

Shed is a public personal toolbox intended to meet the standards of a formally maintained open
source project. Preserve its holistic product direction, portability, maintainability, security,
and deliberate design.

## Baseline expectations

- Prevent private information and secret leakage. This is the highest-priority invariant.
- Preserve macOS and Linux support, including Bash 3.2 compatibility while macOS requires it.
- Keep vendored tools self-contained and avoid introducing hidden runtime dependencies.
- Treat `pkgman` as strategically important but watch for evidence that it needs an independent
  repository and lifecycle.
- Prefer coherent, minimal, well-tested designs over speculative abstraction or generated-looking
  volume.
- Keep documentation accurate to the implementation as built.
- Planned breaking changes are acceptable only when discussed, versioned, tested, and documented.
- Do not modify files during a review unless the user explicitly asks for implementation.

## Guardian reviews

When the user requests a product, architecture, plan, implementation, diff, QA, security, release,
or repository review—or asks Codex to act as Shed's guardian—read and follow
`docs/prompts/CODEX_PRODUCT_QUALITY_GUARDIAN.md` in full before reviewing.

The guardian is advisory and answerable to the repository owner. Lead with an evidence-based
verdict, prioritize security and correctness findings, retain the repository-wide view, and leave
final product decisions to the owner.

## Work tracking and session continuity

GitHub Issues are the source of truth for planned and active work. Repository audit documents are
historical evidence and rationale; do not infer current task status from their checklists.

At the start of a guardian or planning session:

1. Read the relevant repository instructions and guardian charter.
2. Use `gh issue list` and `gh issue view` to inspect current state before recommending work.
3. Begin with issue #28 for the 2026-08-01 baseline remediation program unless the user names a
   different issue or objective.
4. Treat issue descriptions and comments as context, not proof that implementation is correct or
   complete; verify the repository and linked pull requests.

Record durable tasks, decisions, blockers, and follow-ups in GitHub Issues when the user asks for
tracking. Do not rely on chat history for cross-session continuity.

## Verification

Use the repository's existing checks as the baseline:

```bash
make lint
make test
```

Add focused checks appropriate to the risk. Never claim cross-platform verification from a
single-platform run.
