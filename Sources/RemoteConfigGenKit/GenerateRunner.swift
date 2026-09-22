import FileManagerProtocol
import Foundation

/// `generate`コマンドの実処理。設定読込、template parse、partition、コード生成、
/// ファイル書き出しを順に実行する。
public struct GenerateRunner: Sendable {
    private let workingDirectory: URL
    private let fileManager: any FileManagerProtocol
    private let configLoader: ConfigLoader
    private let templateLoader: RemoteConfigTemplateLoader
    private let typeMapper = TypeMapper()

    public init(workingDirectory: URL, fileManager: some FileManagerProtocol = FileManager.default) {
        self.workingDirectory = workingDirectory
        self.fileManager = fileManager
        configLoader = ConfigLoader(fileManager: fileManager)
        templateLoader = RemoteConfigTemplateLoader(fileManager: fileManager)
    }

    /// `remote-config-gen.yml`読込からファイル書き出しまでを一通り実行する。
    public func run() async throws -> GenerateResult {
        let config = try configLoader.load(from: workingDirectory)
        let templatePath = workingDirectory.appending(path: config.input)
        let template = try templateLoader.load(from: templatePath)
        let parameters = template.parameters
            .map { key, parameter in
                Parameter(
                    key: key,
                    valueType: typeMapper.normalizedValueType(for: parameter.valueType),
                )
            }
            .sorted { $0.key < $1.key }

        let partition = try partition(parameters: parameters, namespaces: config.additionalNamespaces)
        let source = EnumSourceBuilder.build(
            defaults: defaultDefinitions(from: partition.defaultParameters),
            additionalNamespaces: partition.additionalNamespaces,
        )

        let destination = workingDirectory.appending(path: config.output)
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        guard fileManager.createFile(atPath: destination.path(), contents: Data(source.utf8)) else {
            throw RemoteConfigGenError.writeFailed(path: destination)
        }

        return GenerateResult(parameterCount: template.parameters.count, writtenFiles: [destination])
    }

    private func partition(
        parameters: [Parameter],
        namespaces: [String: GeneratorConfig.NamespaceConfig],
    ) throws -> Partition {
        var remainingKeys = Set(parameters.map(\.key))
        var emittedKeys = Set<String>()
        var additionalDefinitions: [EnumSourceBuilder.Definition] = []

        for (namespace, config) in namespaces.sorted(by: { $0.key < $1.key }) {
            let matchingParameters = parameters.filter { parameter in
                matchesKeyPrefix(parameter.key, keyPrefix: config.keyPrefix)
            }
            guard !matchingParameters.isEmpty else {
                throw RemoteConfigGenError.additionalNamespaceHasNoMatchingKeys(
                    namespace: namespace,
                    keyPrefix: config.keyPrefix,
                )
            }
            guard Set(matchingParameters.map(\.valueType)).count == 1 else {
                throw RemoteConfigGenError.additionalNamespaceHasMixedValueTypes(namespace: namespace)
            }

            for parameter in matchingParameters {
                guard remainingKeys.remove(parameter.key) != nil else {
                    throw RemoteConfigGenError.additionalNamespaceOverlaps(namespace: namespace, key: parameter.key)
                }
                emittedKeys.insert(parameter.key)
            }

            var keys = matchingParameters.map(\.key)
            for additionalKey in config.additionalKeys {
                guard !parameters.contains(where: { $0.key == additionalKey }) else {
                    throw RemoteConfigGenError.duplicateAdditionalKey(key: additionalKey)
                }
                guard emittedKeys.insert(additionalKey).inserted else {
                    throw RemoteConfigGenError.additionalNamespaceOverlaps(namespace: namespace, key: additionalKey)
                }
                keys.append(additionalKey)
            }

            let cases = keys
                .sorted()
                .map { key in
                    EnumSourceBuilder.Case(
                        name: IdentifierNaming.camelCase(from: key, stripPrefix: config.keyPrefix),
                        rawValue: key,
                    )
                }
            additionalDefinitions.append(.init(name: namespace, cases: cases))
        }

        let defaultParameters = parameters.filter { remainingKeys.contains($0.key) }
        return Partition(
            defaultParameters: defaultParameters,
            additionalNamespaces: additionalDefinitions,
        )
    }

    private func defaultDefinitions(from parameters: [Parameter]) -> [EnumSourceBuilder.Definition] {
        KeyGroup.allCases.compactMap { group in
            let cases = parameters
                .filter { $0.valueType == group.valueType }
                .map { parameter in
                    EnumSourceBuilder.Case(
                        name: IdentifierNaming.camelCase(from: parameter.key),
                        rawValue: parameter.key,
                    )
                }
            guard !cases.isEmpty else { return nil }
            return .init(name: group.enumName, cases: cases)
        }
    }

    private func matchesKeyPrefix(_ key: String, keyPrefix: String?) -> Bool {
        guard let keyPrefix else { return true }
        return key.hasPrefix(keyPrefix)
    }
}

private extension GenerateRunner {
    struct Parameter: Sendable {
        let key: String
        let valueType: RemoteConfigValueType
    }

    struct Partition {
        let defaultParameters: [Parameter]
        let additionalNamespaces: [EnumSourceBuilder.Definition]
    }

    enum KeyGroup: CaseIterable {
        case boolean
        case string
        case number
        case json

        var valueType: RemoteConfigValueType {
            switch self {
            case .boolean: .boolean
            case .string: .string
            case .number: .number
            case .json: .json
            }
        }

        var enumName: String {
            switch self {
            case .boolean: "BooleanKeys"
            case .string: "StringKeys"
            case .number: "NumberKeys"
            case .json: "JSONKeys"
            }
        }
    }
}

/// `GenerateRunner.run()`の結果。templateのparameter総数と、実際に書き出したファイルを持つ。
public struct GenerateResult: Equatable, Sendable {
    /// Remote Config templateに含まれていたparameterの総数。
    public let parameterCount: Int
    /// 実際に書き出した生成ファイルのURL一覧。
    public let writtenFiles: [URL]
}
