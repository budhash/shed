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

## Verification

Use the repository's existing checks as the baseline:

```bash
make lint
make test
```

Add focused checks appropriate to the risk. Never claim cross-platform verification from a
single-platform run.
