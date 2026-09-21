# RemoteConfigGen

Firebase Remote Config JSON → type-safe Swift code generation. Configuration-driven naming and
output shapes (not hardcoded). See README for design rationale and output format.

## Development workflow

- `mise run setup` — install tools, configure Git hooks
- `mise run check` — format, lint, build, test, docsync
- `mise run test` — run the test suite
- See `.mise.toml` for the full task list (`mise tasks`)
- Git hooks in `.githooks/` enforce format + lint on staged changes
- Keep commits small and easy to revert

## Code standards

- Three-target layout: `RemoteConfigGen` (executable, entry point only) → `RemoteConfigGenCLI`
  (ArgumentParser command definitions) → `RemoteConfigGenKit` (all business logic, testable)
- Command/Runner split: a `Command.run()` in CLI validates arguments and delegates to a
  `*Runner` in Kit; it holds no logic of its own
- Kit is organized by domain, not by layer: `Config/` (config.yml parsing), `TemplateParsing/`
  (remoteconfig.json parsing), `TypeMapping/` (valueType → Swift type), `CodeGeneration/`
  (enum/static-let source generation, sharing `EnumSourceBuilder` for the common
  header/declaration/doc-comment scaffolding)
- CLI logs through `swift-log` (`Logging` product); `RemoteConfigGen` (the executable target)
  bootstraps `StreamLogHandler.standardOutput` once at startup — without that bootstrap call,
  `Logger` calls are silently dropped
- File I/O goes through `Ryu0118/FileManagerProtocol`, not `FileManager.default` directly: types
  that touch the filesystem take `fileManager: some FileManagerProtocol = FileManager.default` in
  their initializer and store it as `any FileManagerProtocol`, matching the pattern in Egg/x8
- Swift 6 strict-concurrency compatible; default to package-internal access, `public` only when
  another module needs the symbol
- Doc comments required for public APIs (this project writes them in English, not Japanese)
