# RemoteConfigGen

Swift executable package with a small Kit target and Swift Testing.

## Commands

- `mise run setup` — install the pinned SwiftFormat, SwiftLint, my-swift-linter, docsync, and gitnagg tools, initialize docsync, and configure Git hooks.
- `mise run format` — format Swift sources.
- `mise run lint` — run strict SwiftLint.
- `mise run ast-lint` — run my-swift-linter.
- `mise run ast-fix` — run my-swift-linter autofix.
- `mise run build` — build the executable package.
- `mise run test` — run the test suite.
- `mise run check` — format, lint, AST lint, build, test, and docsync.
- `mise run docsync-check` — verify source and documentation checksums.
- `mise run update-docsync-checksum` — update source and documentation checksums.
- `mise run run` — run `RemoteConfigGen`.

The project uses `.mise.toml` as the single source of truth for development commands. Keep task commands there rather than adding another task runner.

## Architecture

- `Sources/RemoteConfigGen/` contains the executable entry point only.
- `Sources/RemoteConfigGenKit/` contains reusable, testable application logic.
- `Tests/RemoteConfigGenKitTests/` contains Kit tests.

Keep Swift 6 strict-concurrency compatibility in mind. Prefer package-internal access by default and add `public` only when another target or package needs the symbol. Add doc comments to non-obvious public APIs and concise comments for compatibility constraints.

## Agent harness

- Claude Code hooks live under `.claude/`.
- Codex hooks live under `.codex/`.
- Shared implementation scripts live under `scripts/`.
- `.githooks/pre-commit` runs staged Swift formatting and linting for normal Git commits.
- Keep commits small and easy to revert.
