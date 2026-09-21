# RemoteConfigGen

A codegen CLI that turns a Firebase Remote Config template (the `parameters`/`conditions`
JSON exported by `firebase remoteconfig:get`) into type-safe Swift. Boolean parameters become
an enum; every other value type becomes a namespaced, typed key. Reads its own settings from a
`config.yml` in the current directory (input path, output directory, naming, per-value-type
output shape — none of it hardcoded).

Intended to run the same way SwiftGen does: as a step in `mise run gen`, not interactively.

## Commands

```sh
# Install the development tools.
mise run setup

# Build and test.
mise run build
mise run test

# Run all checks.
mise run check

# Run the executable.
mise run run
```
