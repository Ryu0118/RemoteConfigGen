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

    /// config.yml読込からファイル書き出しまでを一通り実行する。
    public func run() async throws -> GenerateResult {
        let config = try configLoader.load(from: workingDirectory)
        let templatePath = workingDirectory.appending(path: config.input.remoteConfigJSON)
        let template = try templateLoader.load(from: templatePath)

        let generatedFiles = generatedFiles(from: template, config: config)

        let outputDirectory = workingDirectory.appending(path: config.output.directory)
        var writtenFiles: [URL] = []
        for file in generatedFiles {
            let destination = outputDirectory.appending(path: file.fileName)
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            guard fileManager.createFile(atPath: destination.path(), contents: Data(file.source.utf8)) else {
                throw RemoteConfigGenError.writeFailed(path: destination)
            }
            writtenFiles.append(destination)
        }

        return GenerateResult(parameterCount: template.parameters.count, writtenFiles: writtenFiles)
    }

    /// config.ymlとRemote Configテンプレートから、書き出すべき生成コードを計算する（ファイルI/Oは行わない）。
    private func generatedFiles(
        from template: RemoteConfigTemplate,
        config: GeneratorConfig,
    ) -> [(fileName: String, source: String)] {
        let typeMapper = TypeMapper(config: config)
        let conditionExpressions = Dictionary(
            uniqueKeysWithValues: template.conditions.map { ($0.name, $0.expression) },
        )

        var boolParameters: [NamedParameter] = []
        var nonBoolParameters: [NamedParameter] = []
        for (key, parameter) in template.parameters.sorted(by: { $0.key < $1.key }) {
            let swiftType = typeMapper.swiftType(for: parameter.valueType)
            let named = NamedParameter(
                key: key,
                swiftType: swiftType,
                conditionalValueKeys: Array(parameter.conditionalValues.keys),
            )
            if swiftType == .bool {
                boolParameters.append(named)
            } else {
                nonBoolParameters.append(named)
            }
        }

        var result: [(fileName: String, source: String)] = []

        if !boolParameters.isEmpty {
            let source = BoolEnumGenerator(config: config).generate(
                parameters: boolParameters,
                conditionExpressions: conditionExpressions,
            )
            result.append((config.boolOutput.resolvedFileName, source))
        }

        if !nonBoolParameters.isEmpty {
            let source = NonBoolKeysGenerator(config: config).generate(
                parameters: nonBoolParameters,
                conditionExpressions: conditionExpressions,
            )
            result.append((config.nonBoolOutput.resolvedFileName, source))
        }

        return result
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
