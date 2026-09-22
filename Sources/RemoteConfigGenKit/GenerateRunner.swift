import FileManagerProtocol
import Foundation

/// `generate`コマンドの実処理。Config読込 → Template parse → Type mapping → Code生成 →
/// ファイル書き出し、という直列ステップを順に呼ぶオーケストレーター。
public struct GenerateRunner: Sendable {
    private let workingDirectory: URL
    private let fileManager: any FileManagerProtocol
    private let configLoader: ConfigLoader
    private let templateLoader: RemoteConfigTemplateLoader

    public init(workingDirectory: URL, fileManager: some FileManagerProtocol = FileManager.default) {
        self.workingDirectory = workingDirectory
        self.fileManager = fileManager
        configLoader = ConfigLoader(fileManager: fileManager)
        templateLoader = RemoteConfigTemplateLoader(fileManager: fileManager)
    }

    /// remote-config-gen.yml読込からファイル書き出しまでを一通り実行する。
    public func run() async throws -> GenerateResult {
        let config = try configLoader.load(from: workingDirectory)
        let templatePath = workingDirectory.appending(path: config.input)
        let template = try templateLoader.load(from: templatePath)

        let typeMapper = TypeMapper(config: config)
        let conditionExpressions = Dictionary(
            uniqueKeysWithValues: template.conditions.map { ($0.name, $0.expression) },
        )
        let namedParameters = template.parameters
            .sorted { $0.key < $1.key }
            .map { key, parameter in
                NamedParameter(
                    key: key,
                    swiftType: typeMapper.swiftType(for: parameter.valueType),
                    conditionalValueKeys: Array(parameter.conditionalValues.keys),
                )
            }

        var writtenFiles: [URL] = []
        for output in config.outputs {
            let generated = try generate(
                output: output,
                config: config,
                parameters: namedParameters,
                conditionExpressions: conditionExpressions,
            )
            guard let generated else { continue }

            let destination = workingDirectory.appending(path: generated.path)
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            guard fileManager.createFile(atPath: destination.path(), contents: Data(generated.source.utf8)) else {
                throw RemoteConfigGenError.writeFailed(path: destination)
            }
            writtenFiles.append(destination)
        }

        return GenerateResult(parameterCount: template.parameters.count, writtenFiles: writtenFiles)
    }

    /// 1つの`OutputConfig`から生成コードを組み立てる（ファイルI/Oは行わない）。対象parameterが
    /// 0件の場合は`nil`を返し、空ファイルの書き出しを避ける。
    private func generate(
        output: GeneratorConfig.OutputConfig,
        config: GeneratorConfig,
        parameters: [NamedParameter],
        conditionExpressions: [String: String],
    ) throws -> (path: String, source: String)? {
        switch output {
        case let .enumOutput(enumOutput):
            var boolParameters = parameters
                .filter { $0.swiftType == .bool }
                .filter { matchesKeyPrefix($0.key, keyPrefix: enumOutput.keyPrefix) }

            for key in enumOutput.additionalKeys.sorted() {
                guard !parameters.contains(where: { $0.key == key }) else {
                    throw RemoteConfigGenError.duplicateAdditionalKey(key: key)
                }
                boolParameters.append(NamedParameter(key: key, swiftType: .bool))
            }
            boolParameters.sort { $0.key < $1.key }

            guard !boolParameters.isEmpty else { return nil }
            let source = BoolEnumGenerator(config: config, output: enumOutput).generate(
                parameters: boolParameters,
                conditionExpressions: conditionExpressions,
            )
            return (enumOutput.path, source)

        case let .keysOutput(keysOutput):
            let nonBoolParameters = parameters.filter { $0.swiftType != .bool }
            guard !nonBoolParameters.isEmpty else { return nil }
            let source = NonBoolKeysGenerator(config: config, output: keysOutput).generate(
                parameters: nonBoolParameters,
                conditionExpressions: conditionExpressions,
            )
            return (keysOutput.path, source)
        }
    }

    /// `keyPrefix`が未指定なら常に対象。指定されていれば、keyがその接頭辞で始まる場合のみ対象。
    private func matchesKeyPrefix(_ key: String, keyPrefix: String?) -> Bool {
        guard let keyPrefix else { return true }
        return key.hasPrefix(keyPrefix)
    }
}

/// `GenerateRunner.run()`の結果。テンプレートに含まれていたparameter総数と、実際に書き出したファイルを両方持つ。
/// parameter数を別途持つのは、0件生成時に「設定ミスで空なのか、意図通り0件なのか」をCLI側で区別できるようにするため。
public struct GenerateResult: Equatable, Sendable {
    /// Remote Configテンプレートに含まれていたparameterの総数。
    public let parameterCount: Int
    /// 実際に書き出したファイルのURL一覧。
    public let writtenFiles: [URL]
}
