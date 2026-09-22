import FileManagerProtocol
import Foundation
import Yams

/// カレントディレクトリの `remote-config-gen.yml` を読み込み `GeneratorConfig` へ変換する。
public struct ConfigLoader: Sendable {
    private let fileManager: any FileManagerProtocol

    public init(fileManager: some FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// `directory/remote-config-gen.yml` を読み込む。見つからなければ `.configNotFound` を投げる。
    public func load(from directory: URL) throws -> GeneratorConfig {
        let configPath = directory.appending(path: "remote-config-gen.yml")
        guard let data = fileManager.contents(atPath: configPath.path()) else {
            throw RemoteConfigGenError.configNotFound(directory: directory)
        }
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw RemoteConfigGenError.invalidConfig(reason: "remote-config-gen.yml is not valid UTF-8.")
        }
        return try parse(yamlString)
    }

    func parse(_ yamlString: String) throws -> GeneratorConfig {
        let raw = try decode(yamlString)

        guard let input = raw.input else {
            throw RemoteConfigGenError.invalidConfig(reason: "`input` is required.")
        }

        var config = GeneratorConfig(input: input)

        if let accessLevel = raw.accessLevel {
            guard let mapped = GeneratorConfig.AccessLevel(rawValue: accessLevel) else {
                throw RemoteConfigGenError.invalidConfig(
                    reason: "`access_level` must be one of: public, package, internal. Got \"\(accessLevel)\".",
                )
            }
            config.accessLevel = mapped
        }
        if let headerComment = raw.headerComment {
            config.headerComment = headerComment
        }
        if let includeConditionSummary = raw.includeConditionSummary {
            config.includeConditionSummary = includeConditionSummary
        }
        if let unspecifiedValueType = raw.unspecifiedValueType {
            guard let mapped = GeneratorConfig.FallbackType(rawValue: unspecifiedValueType) else {
                throw RemoteConfigGenError.invalidConfig(
                    reason: "`unspecified_value_type` must be one of: string. Got \"\(unspecifiedValueType)\".",
                )
            }
            config.unspecifiedValueType = mapped
        }

        config.outputs = try (raw.outputs ?? []).map(makeOutput)

        return config
    }

    private func decode(_ yamlString: String) throws -> RawConfig {
        do {
            return try YAMLDecoder().decode(RawConfig.self, from: yamlString)
        } catch {
            throw RemoteConfigGenError.invalidConfig(reason: error.localizedDescription)
        }
    }

    private func makeOutput(from raw: RawOutput) throws -> GeneratorConfig.OutputConfig {
        switch raw.type {
        case "enum":
            guard let name = raw.name else {
                throw RemoteConfigGenError.invalidConfig(reason: "An `enum` output requires `name`.")
            }
            guard let path = raw.path else {
                throw RemoteConfigGenError.invalidConfig(reason: "An `enum` output requires `path`.")
            }
            return .enumOutput(
                GeneratorConfig.EnumOutput(
                    name: name,
                    keyPrefix: raw.keyPrefix,
                    additionalKeys: raw.additionalKeys ?? [],
                    path: path,
                    rawValue: raw.rawValue ?? true,
                    conformances: raw.conformances ?? ["CaseIterable", "Sendable"],
                ),
            )
        case "keys":
            guard let path = raw.path else {
                throw RemoteConfigGenError.invalidConfig(reason: "A `keys` output requires `path`.")
            }
            return .keysOutput(
                GeneratorConfig.KeysOutput(
                    namespace: raw.namespace ?? "RemoteConfigKeys",
                    keyType: raw.keyType ?? "RemoteConfigKey",
                    path: path,
                ),
            )
        case let other:
            let gotValue = other.map { "\"\($0)\"" } ?? "nothing"
            throw RemoteConfigGenError.invalidConfig(
                reason: "Each `outputs` entry needs a `type` of either \"enum\" or \"keys\". Got \(gotValue).",
            )
        }
    }
}
