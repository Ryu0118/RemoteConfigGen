# RemoteConfigGen

A codegen CLI that turns a Firebase Remote Config template (the `parameters`/`conditions`
JSON exported by `firebase remoteconfig:get`) into type-safe Swift. Boolean parameters become
an enum; every other value type becomes a namespaced, typed key. Reads its own settings from a
`config.yml` in the current directory (input path, output directory, naming, per-value-type
output shape — none of it hardcoded).

Intended to run the same way SwiftGen does: as a step in `mise run gen`, not interactively.

## Usage

```sh
RemoteConfigGen generate --config-directory /path/to/project   # defaults to the current directory
```

`config.yml` (in the current directory, or `--config-directory`) needs at least:

```yaml
input:
  remote_config_json: "firebase/remoteconfig.production.json"
output:
  directory: "Sources/RemoteConfigKeys/Generated"
```

Boolean parameters generate a `String`-raw-value enum (default: `FeatureFlag`); every other
value type (String/Double/JSON) generates a typed, namespaced key (default namespace:
`RemoteConfigKeys`, default wrapper type: `RemoteConfigKey<T>`) as `static let`. Every
naming/shape choice is configurable — see `GeneratorConfig` in `RemoteConfigGenKit` for the
full schema.

## Development

```sh
mise run setup   # install tools, configure Git hooks
mise run check   # format, lint, build, test, docsync
mise run test    # run the test suite
```
