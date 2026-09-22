# 🔑 RemoteConfigGen

**Type-safe Swift bindings for Firebase Remote Config, generated from your template.**

[![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-lightgrey)](https://developer.apple.com/macos/)

Firebase Remote Config keys are strings. Every app that reads them ends up
with a hand-maintained enum or a pile of `"the_exact_key_string"` literals
scattered across the codebase — a typo anywhere compiles fine and just quietly
returns the default. RemoteConfigGen reads the same template JSON Firebase
itself exports (`firebase remoteconfig:get`) and generates the Swift side from
it, so the key list has exactly one source of truth and a renamed or removed
parameter is a compile error, not a runtime surprise.

- 🔒 **One source of truth.** The template your team already manages in
  Firebase Console (or in git, via `firebase remoteconfig:get`) is the input.
  Nothing about key names or types is retyped by hand.
- 🧩 **The right shape per value type.** Boolean parameters become a
  `CaseIterable` enum; every other value type (String/Double/JSON) becomes a
  namespaced, typed key — because a single enum can't mix case types, and
  flags are what most callers actually branch on.
- 📎 **Rollout context, not rollout logic.** If a parameter has a percent
  rollout or another condition attached, the generated code carries a doc
  comment naming it. Evaluating the condition stays Firebase's job at
  runtime — RemoteConfigGen never re-implements that.
- ⚙️ **Nothing hardcoded.** Output directory, access level, enum/namespace
  names, the wrapper type, naming convention — all config-driven, so this
  isn't tied to any one project's conventions.

## Table of Contents

- [Installation](#installation)
  - [Other methods](#other-methods)
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
curl -fsSL https://raw.githubusercontent.com/Ryu0118/RemoteConfigGen/main/install.sh | VERSION=0.1.0 bash

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

Or run it directly from a checkout without installing:

```sh
swift run remote-config-gen generate
```

## Quick Start

1. Get a copy of your Remote Config template as JSON — the same file
   `firebase remoteconfig:get` writes:

   ```sh
   firebase remoteconfig:get --output firebase/remoteconfig.production.json
   ```

2. Add a `remote-config-gen.yml` at your repository root:

   ```yaml
   input: "firebase/remoteconfig.production.json"

   outputs:
     - type: enum
       name: FeatureFlag
       key_prefix: "feature_flag_"
       path: "Sources/RemoteConfigKeys/Generated/FeatureFlag.swift"
   ```

3. Generate:

   ```sh
   remote-config-gen generate
   ```

   This reads `remote-config-gen.yml` from the current directory (or pass
   `--config-directory <path>` to point elsewhere), and writes each entry in
   `outputs` to its own `path`.

Run it the same way you'd run SwiftGen: as a step in `mise run gen` (or
whatever your project's codegen task is called), not interactively.

## remote-config-gen.yml Reference

Only `input` is required. `outputs` is a plain list — you write one entry
per file you want, and nothing is generated beyond what's listed (no
opt-out flags to fight with).

```yaml
# ── required ──
input: "firebase/remoteconfig.production.json"

# ── one entry per generated file ──
outputs:
  - type: enum                                    # BOOLEAN parameters -> a Swift enum
    name: FeatureFlag
    path: "Sources/RemoteConfigKeys/Generated/FeatureFlag.swift"
    key_prefix: "feature_flag_"                    # optional: filters keys AND strips this prefix from case names
    additional_keys: []                             # optional: full key strings to include even if absent from the template
    raw_value: true                                 # optional (default true): keep the Remote Config key as a String raw value
    conformances: ["CaseIterable", "Sendable"]       # optional (shown default)

  - type: keys                                     # every other value type (String/Double/JSON) -> namespaced typed keys
    path: "Sources/RemoteConfigKeys/Generated/RemoteConfigKeys.swift"
    namespace: RemoteConfigKeys                      # optional (shown default)
    key_type: RemoteConfigKey                         # optional (shown default): wrapper type name

# ── optional, apply to every output (defaults shown) ──
access_level: public                                # public | package | internal
header_comment: "Auto-generated by RemoteConfigGen. Do not edit."
include_condition_summary: true                     # surface rollout conditions as doc comments
unspecified_value_type: string                       # type used when Firebase Console left a value type unset
```

Most projects only need a single `enum` entry — feature flags are what
callers actually branch on, so that's the common case. Add a `keys` entry
only if you also want typed access to non-boolean parameters. Skip a
section entirely and nothing is generated for it; there's no `enabled` flag
to remember to flip.

`key_prefix` does two things with one value: it filters which BOOLEAN
parameters this output includes, and it's the prefix stripped from case
names. If your template mixes flags with unrelated BOOLEAN config (e.g. a
`maintenanceMode` toggle sitting next to your `feature_flag_*` keys),
`key_prefix` keeps the unrelated ones out. If you have two independent flag
namespaces in the same template, add two `enum` outputs, each with its own
`key_prefix` and `path`.

`additional_keys` lists flags that don't live in Remote Config at all — one
gated purely by build environment, for instance — so it still gets a `case`
in the generated enum instead of living in a hand-maintained extension.
Entries are full key strings (same `key_prefix` stripping applies to them),
and it's an error for one to also exist in the template — that means the
flag has moved to Remote Config and the entry is now stale.

## What gets generated

Given a template with a boolean flag under a 50% rollout and two plain
parameters:

```json
{
  "parameters": {
    "new_checkout_flow_enabled": {
      "defaultValue": { "value": "true" },
      "valueType": "BOOLEAN",
      "conditionalValues": { "fifty_percent_rollout": { "value": "false" } }
    },
    "welcome_message_variant": { "defaultValue": { "value": "control" }, "valueType": "STRING" },
    "max_upload_size_mb": { "defaultValue": { "value": "50" }, "valueType": "NUMBER" }
  },
  "conditions": [
    { "name": "fifty_percent_rollout", "expression": "percent('seed') <= 50" }
  ]
}
```

`remote-config-gen generate` writes:

```swift
// FeatureFlag.swift
public enum FeatureFlag: String, CaseIterable, Sendable {
    /// Rollout: `percent('seed') <= 50` (condition: "fifty_percent_rollout")
    case newCheckoutFlowEnabled = "new_checkout_flow_enabled"
}
```

```swift
// RemoteConfigKeys.swift
public enum RemoteConfigKeys {
    public static let welcomeMessageVariant = RemoteConfigKey<String>("welcome_message_variant")
    public static let maxUploadSizeMb = RemoteConfigKey<Double>("max_upload_size_mb")
}
```

`RemoteConfigKey<T>` isn't defined by RemoteConfigGen — it's a small wrapper
type you write once in your own codebase (just a key name plus a phantom
type), matching whatever your `RemoteConfigClient`/SDK wrapper expects. This
keeps RemoteConfigGen decoupled from any particular Remote Config client
implementation.

## Commands

```sh
remote-config-gen generate [--config-directory <path>]
```

`generate` is also the default subcommand, so `remote-config-gen` with no
arguments does the same thing as `remote-config-gen generate`.

## Development

```sh
mise run setup   # install tools, configure Git hooks
mise run check   # format, lint, build, test, docsync
mise run test    # run the test suite
```

See `.mise.toml` for the full task list (`mise tasks`).

## License

RemoteConfigGen is available under the MIT License. See [LICENSE](LICENSE) for details.
