# RemoteConfigGen

Swift executable package with a small Kit target and Swift Testing.

## Commands

`.mise.toml` is the single source of truth for development commands. Run `mise tasks` for the list, or `mise run setup` to get started. Keep task commands there rather than adding another task runner or duplicating descriptions elsewhere.

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
