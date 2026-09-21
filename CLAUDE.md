# RemoteConfigGen

Codegen CLI: Firebase Remote Config template JSON (`parameters`/`conditions`) → type-safe Swift.
Boolean parameters generate an enum (default name `FeatureFlag`); every other value type
(String/Double/JSON) generates a typed, namespaced key (default namespace `RemoteConfigKeys`,
default wrapper type `RemoteConfigKey<T>`) as `static let` — a single enum cannot hold cases of
different associated-value types, so non-Bool parameters can't join the Bool enum. Condition
info (percent rollouts, etc.) is surfaced only as a doc comment on the generated symbol; actual
condition evaluation stays the Firebase SDK's job at runtime. All naming/shape choices are
config-driven (see `config.yml` schema once implemented), not hardcoded, since this is meant to
be a general-purpose tool like Egg or xcs, not project-specific.

Not yet implemented: template parsing, type mapping, and code generation themselves — this
scaffold is the harness only.

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
