# 🔑 RemoteConfigGen

**Type-safe Swift key enums generated from a Firebase Remote Config template.**

Firebase Remote Config keys are strings. A hand-maintained list can silently
drift from the template, so RemoteConfigGen reads the JSON exported by
`firebase remoteconfig:get` and generates the complete key list from that one
source of truth.

- 🔒 The Firebase template is the source of truth for key names and value types.
- 🧩 Keys are grouped into nested enums by `BOOLEAN`, `STRING`, `NUMBER`, and
  `JSON` value type.
- 📎 A namespace with a `key_prefix` can extract a related set of keys while
  keeping those keys out of the default groups.
- ⚙️ The generated API is deliberately small: every generated key is a
  `String` raw-value enum case.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [remote-config-gen.yml Reference](#remote-config-genyml-reference)
- [What gets generated](#what-gets-generated)
- [Commands](#commands)
- [Development](#development)
- [License](#license)

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/Ryu0118/RemoteConfigGen/main/install.sh | bash
```

To update, run the same command. It skips the download if already up-to-date.

```sh
# Install a specific version
curl -fsSL https://raw.githubusercontent.com/Ryu0118/RemoteConfigGen/main/install.sh | VERSION=0.7.0 bash

# Force reinstall
curl -fsSL https://raw.githubusercontent.com/Ryu0118/RemoteConfigGen/main/install.sh | FORCE=1 bash
```

### Other methods

#### Nest ([mtj0928/nest](https://github.com/mtj0928/nest))

```sh
nest install Ryu0118/RemoteConfigGen
```

#### Mise ([jdx/mise](https://github.com/jdx/mise))

```sh
mise use -g github:Ryu0118/RemoteConfigGen
```

#### Build from source

Requires **macOS 26+** and **Swift 6.2**.

```sh
git clone https://github.com/Ryu0118/RemoteConfigGen.git
cd RemoteConfigGen
swift build -c release
cp .build/release/remote-config-gen /usr/local/bin/remote-config-gen
```

Or run it directly from a checkout:

```sh
swift run remote-config-gen generate
```

## Quick Start

1. Export the Remote Config template that Firebase manages:

   ```sh
   firebase remoteconfig:get --output firebase/remoteconfig.production.json
   ```

2. Add `remote-config-gen.yml` to the repository root:

   ```yaml
   input: firebase/remoteconfig.production.json
   output: Sources/RemoteConfigKeys/Generated/RemoteConfigKeys.swift

   additional_namespaces:
     FeatureFlag:
       key_prefix: feature_flag_
       additional_keys: [feature_flag_localOnly]
   ```

3. Generate the Swift file from the repository root:

   ```sh
   remote-config-gen generate
   ```

   The paths in the configuration are relative to the directory containing
   `remote-config-gen.yml`. `--config-directory <path>` can be used when the
   command is run from another directory.

Run this as part of the project's code generation task, such as `mise run gen`.

## remote-config-gen.yml Reference

The schema has one required input path, one required output path, and an
optional map of additional namespaces. There is no output list, type selector,
opt-out flag, or repeated output path.

```yaml
input: firebase/remoteconfig.production.json
output: Sources/RemoteConfigKeys/Generated/RemoteConfigKeys.swift

additional_namespaces:
  FeatureFlag:
    key_prefix: feature_flag_
    additional_keys: [feature_flag_localOnly]
```

### Top-level fields

| Field | Required | Meaning |
| --- | --- | --- |
| `input` | Yes | Path to the Firebase Remote Config JSON, relative to the config directory. |
| `output` | Yes | Path of the single generated Swift file, relative to the config directory. |
| `additional_namespaces` | No | Map from generated nested enum name to namespace options. |

### Namespace fields

| Field | Required | Meaning |
| --- | --- | --- |
| `key_prefix` | No | Only parameters starting with this prefix are extracted. The prefix is also removed from their case names. If omitted, all parameters are candidates. |
| `additional_keys` | No | Full key strings that are not present in the JSON but should be added to the generated enum. |

The default namespace is generated from every parameter in the template. A
parameter is placed in one of these nested enums according to its value type:

- `BOOLEAN` → `BooleanKeys`
- `STRING` → `StringKeys`
- `NUMBER` → `NumberKeys`
- `JSON` → `JSONKeys`

Empty groups are omitted. A missing or `PARAMETER_VALUE_TYPE_UNSPECIFIED`
value type is treated as `STRING`.

Each entry under `additional_namespaces` must match at least one template
parameter. All matched parameters must have the same value type; otherwise
generation fails because the namespace's type cannot be inferred. Matched
parameters are removed from the default groups, so a raw key appears in only
one generated enum. `additional_keys` use the type inferred from the matched
parameters and are included even though they are absent from the template.

An `additional_keys` entry that already exists in the template is an error. It
means the key has moved into Remote Config and the configuration is stale.

## What gets generated

For a template containing ordinary parameters and `feature_flag_*` boolean
parameters, `RemoteConfigKeys.swift` has this shape:

```swift
// Auto-generated by RemoteConfigGen. Do not edit.

public enum RemoteConfigKeys {
    public enum BooleanKeys: String, CaseIterable, Sendable {
        case maintenanceModeStudyLegends
    }
    public enum StringKeys: String, CaseIterable, Sendable {
        case forceUpdateVersion
    }
    public enum NumberKeys: String, CaseIterable, Sendable {
        case maxUploadSizeMb
    }
    public enum JSONKeys: String, CaseIterable, Sendable {
        case banWords
    }
    public enum FeatureFlag: String, CaseIterable, Sendable {
        case goalsApiWrite = "feature_flag_goalsApiWrite"
        case localOnly = "feature_flag_localOnly"
    }
}
```

The case name is derived from the key. For an additional namespace, its
`key_prefix` is removed before the case name is converted to lower camel case.
The raw value always remains the complete Remote Config key.

## Commands

```sh
remote-config-gen generate [--config-directory <path>]
```

`generate` is also the default subcommand, so `remote-config-gen` with no
arguments performs the same generation.

## Development

```sh
mise run setup   # install tools, configure Git hooks
mise run check   # format, lint, build, test, docsync
mise run test    # run the test suite
```

See `.mise.toml` for the full task list (`mise tasks`).

## License

RemoteConfigGen is available under the MIT License. See [LICENSE](LICENSE) for details.
