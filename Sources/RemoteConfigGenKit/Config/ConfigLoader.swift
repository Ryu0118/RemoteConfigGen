import Foundation
import Yams

/// カレントディレクトリの `config.yml` を読み込み `GeneratorConfig` へ変換する。
public struct ConfigLoader: Sendable {
    public init() {}

    /// `directory/config.yml` を読み込む。見つからなければ `.configNotFound` を投げる。
    public func load(from directory: URL) throws -> GeneratorConfig {
        let configPath = directory.appending(path: "config.yml")
        guard let data = FileManager.default.contents(atPath: configPath.path()) else {
            throw RemoteConfigGenError.configNotFound(directory: directory)
        }
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw RemoteConfigGenError.invalidConfig(reason: "config.yml is not valid UTF-8.")
        }
        return try parse(yamlString)
    }

    func parse(_ yamlString: String) throws -> GeneratorConfig {
        let raw = try decode(yamlString)

        guard let remoteConfigJSON = raw.input?.remoteConfigJSON else {
            throw RemoteConfigGenError.invalidConfig(reason: "`input.remote_config_json` is required.")
        }
        guard let outputDirectory = raw.output?.directory else {
            throw RemoteConfigGenError.invalidConfig(reason: "`output.directory` is required.")
        }

        var config = GeneratorConfig(
            input: .init(remoteConfigJSON: remoteConfigJSON),
            output: .init(directory: outputDirectory),
        )

        try apply(raw.output, to: &config)
        try apply(raw.naming, to: &config)
        apply(raw.boolOutput, to: &config)
        apply(raw.nonBoolOutput, to: &config)
        try apply(raw.typeFallback, to: &config)
        apply(raw.documentation, to: &config)

        return config
    }

    private func decode(_ yamlString: String) throws -> RawConfig {
        do {
            return try YAMLDecoder().decode(RawConfig.self, from: yamlString)
        } catch {
            throw RemoteConfigGenError.invalidConfig(reason: error.localizedDescription)
        }
    }

    private func apply(_ raw: RawOutput?, to config: inout GeneratorConfig) throws {
        if let accessLevel = raw?.accessLevel {
            guard let mapped = GeneratorConfig.AccessLevel(rawValue: accessLevel) else {
                throw RemoteConfigGenError.invalidConfig(
                    reason: "`output.access_level` must be one of: public, package, internal. Got \"\(accessLevel)\".",
                )
            }
            config.output.accessLevel = mapped
        }
        if let headerComment = raw?.headerComment {
            config.output.headerComment = headerComment
        }
    }

    private func apply(_ raw: RawNaming?, to config: inout GeneratorConfig) throws {
        guard let caseConvention = raw?.caseConvention else { return }
        guard let mapped = GeneratorConfig.CaseConvention(rawValue: caseConvention) else {
            throw RemoteConfigGenError.invalidConfig(
                reason: "`naming.case_convention` must be one of: camelCase. Got \"\(caseConvention)\".",
            )
        }
        config.naming.caseConvention = mapped
    }

    private func apply(_ raw: RawBoolOutput?, to config: inout GeneratorConfig) {
        if let enumName = raw?.enumName {
            config.boolOutput.enumName = enumName
            config.boolOutput.fileName = raw?.fileName ?? "\(enumName).swift"
        }
        if let fileName = raw?.fileName {
            config.boolOutput.fileName = fileName
        }
        if let rawValue = raw?.rawValue {
            config.boolOutput.rawValue = rawValue
        }
        if let conformances = raw?.conformances {
            config.boolOutput.conformances = conformances
        }
    }

    private func apply(_ raw: RawNonBoolOutput?, to config: inout GeneratorConfig) {
        if let namespace = raw?.namespace {
            config.nonBoolOutput.namespace = namespace
            config.nonBoolOutput.fileName = raw?.fileName ?? "\(namespace).swift"
        }
        if let fileName = raw?.fileName {
            config.nonBoolOutput.fileName = fileName
        }
        if let keyType = raw?.keyType {
            config.nonBoolOutput.keyType = keyType
        }
    }

    private func apply(_ raw: RawTypeFallback?, to config: inout GeneratorConfig) throws {
        guard let unspecifiedValueType = raw?.unspecifiedValueType else { return }
        guard let mapped = GeneratorConfig.FallbackType(rawValue: unspecifiedValueType) else {
            throw RemoteConfigGenError.invalidConfig(
                reason: "`type_fallback.unspecified_value_type` must be one of: string. "
                    + "Got \"\(unspecifiedValueType)\".",
            )
        }
        config.typeFallback.unspecifiedValueType = mapped
    }

    private func apply(_ raw: RawDocumentation?, to config: inout GeneratorConfig) {
        if let includeConditionSummary = raw?.includeConditionSummary {
            config.documentation.includeConditionSummary = includeConditionSummary
        }
    }
}
