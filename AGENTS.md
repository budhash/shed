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
2. Check the branch and working tree before drawing conclusions. Preserve user changes and do not
   switch branches, stage files, or modify work during a read-only review.
3. Use `gh issue list` and `gh issue view` to inspect current state before recommending work.
4. Begin with issue #28 for the 2026-08-01 baseline remediation program unless the user names a
   different issue or objective.
5. Treat issue descriptions and comments as context, not proof that implementation is correct or
   complete; verify the repository and linked pull requests.

Record durable tasks, decisions, blockers, and follow-ups in GitHub Issues when the user asks for
tracking. Do not rely on chat history for cross-session continuity.

If GitHub is unavailable, report that live status could not be established. Do not substitute an
audit checklist, local branch, cached issue description, or memory for current issue state. Safe
local analysis may continue when it is useful, but label its status assumptions explicitly.

For tracked work, keep the issue lifecycle accurate: record material decisions and blockers, link
the implementation pull request, verify acceptance criteria and required checks, then close the
issue or update the parent tracker only after completion. Do not create, edit, close, or comment on
issues unless the user has authorized that external change.

## Change delivery

- Do not commit directly to `main`. When implementation is authorized, use a focused branch and a
  pull request with the problem, scope, risks, compatibility impact, and verification performed.
- Keep unrelated changes out of the branch and preserve pre-existing worktree modifications.
- Treat passing CI as evidence, not proof of correctness. Apply the relevant guardian review
  before recommending a merge.
- Do not push, open or merge a pull request, delete a branch, publish a release, or otherwise
  change remote state unless the user authorizes that action.
- After an authorized merge, verify the pull request state and confirm that local `main` is clean
  and synchronized with `origin/main`.

## Safe inspection and reporting

Inspect narrowly and avoid printing broad environment dumps, credential-bearing configuration,
full Git identity metadata, or unredacted diagnostic logs. If sensitive or private information is
encountered, do not reproduce it; identify only the minimum location needed for remediation and
follow the guardian charter's disclosure guidance.

## Verification

Use the repository's existing checks as the baseline:

```bash
make lint
make test
```

Add focused checks appropriate to the risk. Never claim cross-platform verification from a
single-platform run.
